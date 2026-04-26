const SUPABASE_URL = 'https://qjysynvuenridakgicvz.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqeXN5bnZ1ZW5yaWRha2dpY3Z6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0OTY0MjUsImV4cCI6MjA4OTA3MjQyNX0.BsCARG2nYsjiB8SS_wIGf0svwLE3I5KyrfsvHvkRJP0';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

let activeSosId = null;
let map, victimMarker;
let stationMarkers = [];
let trackingPath = null; // Polyline to show victim movement
let victimPathPoints = [];

async function init() {
    updateTime();
    setInterval(updateTime, 1000);
    
    initLeaflet();
    fetchAlerts();
    subscribeToAlerts();
    addLog("TACTICAL SYSTEM ENGAGED", "success");
}

function addLog(msg, type = '') {
    const area = document.getElementById('log-entries');
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    const time = new Date().toLocaleTimeString([], { hour12: false });
    entry.innerText = `[${time}] ${msg}`;
    area.prepend(entry);
    if (area.childNodes.length > 50) area.removeChild(area.lastChild);
}

async function dispatchOfficer(sosId) {
    addLog(`DISPATCHING UNIT TO SOS: ${sosId.substring(0,8)}`, "action");
    const { error } = await sb
        .from('police_responses')
        .update({ status: 'dispatched' })
        .eq('sos_id', sosId);
        
    if (!error) {
        addLog("DISPATCH CONFIRMED BY COMMAND", "success");
        fetchAlerts();
    } else {
        addLog(`DISPATCH FAILED: ${error.message}`, "critical");
    }
}

async function updateAlertStatus(sosId, newStatus) {
    const { error } = await sb
        .from('sos_alerts')
        .update({ status: newStatus })
        .eq('id', sosId);
        
    if (!error) {
        addLog(`ALERT STATUS: ${newStatus.toUpperCase()}`, "action");
    }
}

function playAlertSound() {
    // Simple synth beep for notification
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);

    oscillator.type = 'square';
    oscillator.frequency.setValueAtTime(440, audioCtx.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(880, audioCtx.currentTime + 0.1);
    
    gainNode.gain.setValueAtTime(0.1, audioCtx.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.5);

    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.5);
    
    // Flash header
    const header = document.querySelector('header');
    header.style.background = 'rgba(255, 59, 48, 0.4)';
    setTimeout(() => { header.style.background = 'rgba(10, 10, 10, 0.95)'; }, 500);
}

function handleDispatch() {
    if (activeSosId) {
        dispatchOfficer(activeSosId);
    } else {
        addLog("SELECT ACTIVE SOS BEFORE DISPATCH", "critical");
    }
}

function updateTime() {
    const now = new Date();
    document.getElementById('system-time').innerText = now.toTimeString().split(' ')[0];
}

function initLeaflet() {
    // Initialize map on Bangalore coordinates
    map = L.map('map-container', {
        zoomControl: true,
        attributionControl: false
    }).setView([12.9716, 77.5946], 13);

    // Official OpenStreetMap Tiles (Most reliable fallback)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19
    }).addTo(map);

    // Add a slight delay then force a resize fix
    setTimeout(() => {
        map.invalidateSize();
    }, 500);

    const placeholder = document.querySelector('.map-placeholder');
    if (placeholder) placeholder.style.display = 'none';
}

async function fetchAlerts() {
    const { data, error } = await sb
        .from('police_dashboard_alerts')
        .select('*')
        .order('sos_status', { ascending: false }) // TRIGGERED first
        .order('triggered_at', { ascending: false });

    if (data) {
        renderAlerts(data);
        // Auto-select first triggered alert if none active
        if (!activeSosId && data.length > 0) {
            selectAlert(data[0]);
            addLog("AUTO-SELECTED EMERGENCY INCIDENT", "critical");
        }
    }
}

async function generateAIBriefing(alert) {
    const lat = parseFloat(alert.latitude);
    const lng = parseFloat(alert.longitude);
    if (lat === 0 && lng === 0) return;

    const GEMINI_KEY = 'AIzaSyAyClnHz8Ek_lQCTRbXH7MMIuXSzVDJ-_k';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_KEY}`;
    
    const prompt = `Act as a Police Tactical Advisor. 
    Victim: ${alert.victim_name}. Trigger: ${alert.trigger_type}. 
    Location: ${lat}, ${lng}.
    Provide a professional 1-sentence tactical directive for dispatchers.`;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
        });
        
        if (!response.ok) throw new Error("AI Offline");

        const data = await response.json();
        const brief = data.candidates[0].content.parts[0].text;
        addLog(`AI BRIEF: ${brief}`, "success");
    } catch (e) {
        // ULTIMATE FAIL-SAFE: Static Heuristic Briefing
        let staticBrief = "";
        if (alert.trigger_type === 'manual') staticBrief = "High priority: Manual SOS trigger. Dispatch nearest unit for immediate physical check.";
        else if (alert.trigger_type.includes('fall')) staticBrief = "Possible medical emergency: Fall detected. Dispatch unit with trauma kit.";
        else staticBrief = "Alert triggered. Establishing perimeter and monitoring live GPS breadcrumbs.";
        
        addLog(`TACTICAL BRIEF (HEURISTIC): ${staticBrief}`, "success");
    }
}

function subscribeToAlerts() {
    sb
        .channel('police_alerts')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'police_responses' }, payload => {
            addLog(`EMERGENCY TRIGGERED: NEW UNIT REQUIRED`, "critical");
            playAlertSound();
            fetchAlerts();
        })
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'police_responses' }, payload => {
            addLog(`POLICE RESPONSE UPDATE: ${payload.new.status.toUpperCase()}`, "action");
            fetchAlerts();
        })
        .subscribe();

    sb
        .channel('sos_evidence')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'evidence_items' }, payload => {
            if (activeSosId && payload.new.sos_id === activeSosId) {
                addLog(`NEW EVIDENCE RECEIVED: ${payload.new.type.toUpperCase()}`, "success");
                renderEvidenceItem(payload.new);
            }
        })
        .subscribe();

    sb
        .channel('sos_live_gps')
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'sos_alerts' }, payload => {
            if (activeSosId && payload.new.id === activeSosId) {
                addLog(`GPS UPLINK: ${payload.new.latitude}, ${payload.new.longitude}`);
                updateVictimPosition(payload.new.latitude, payload.new.longitude);
            }
        })
        .subscribe();
}

function updateVictimPosition(lat, lng) {
    const fLat = parseFloat(lat);
    const fLng = parseFloat(lng);
    const pos = [fLat, fLng];
    
    document.getElementById('current-lat').innerText = fLat.toFixed(4);
    document.getElementById('current-lng').innerText = fLng.toFixed(4);
    
    victimPathPoints.push(pos);

    if (victimMarker) {
        victimMarker.setLatLng(pos);
        map.panTo(pos);
    }

    // Update or Create tracking path (Blue glowing line)
    if (trackingPath) {
        trackingPath.setLatLngs(victimPathPoints);
    } else {
        trackingPath = L.polyline(victimPathPoints, {
            color: '#007AFF',
            weight: 3,
            opacity: 0.6,
            dashArray: '5, 10'
        }).addTo(map);
    }
}

function renderAlerts(alerts) {
    const list = document.getElementById('alerts-list');
    list.innerHTML = '';
    document.getElementById('alert-count').innerText = alerts.length;

    if (alerts.length === 0) {
        list.innerHTML = '<div class="empty-state">SCANNING FOR EMERGENCY TRIGGERS...</div>';
        return;
    }

    alerts.forEach(alert => {
        const isActive = activeSosId === alert.sos_id;
        const card = document.createElement('div');
        card.className = `alert-card ${isActive ? 'active' : ''}`;
        
        const time = new Date(alert.triggered_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        
        card.innerHTML = `
            <div class="alert-card-header">
                <h3>${alert.victim_name}</h3>
                <span class="time">${time}</span>
            </div>
            <div class="alert-card-body">
                <span class="trigger-tag">${alert.trigger_type.replace('_', ' ').toUpperCase()}</span>
                <span class="status-tag status-${alert.sos_status}">${alert.sos_status.toUpperCase()}</span>
            </div>
            ${isActive ? '<div class="active-pulse"></div>' : ''}
        `;
        
        card.onclick = () => {
            selectAlert(alert);
            // Re-render to update active classes
            fetchAlerts(); 
        };
        list.appendChild(card);
    });
}

function selectAlert(alert) {
    if (activeSosId === alert.sos_id && map.getZoom() > 15) return;
    
    activeSosId = alert.sos_id;
    const lat = parseFloat(alert.latitude);
    const lng = parseFloat(alert.longitude);
    const pos = [lat, lng];

    console.log(`KAWACH: Centering on [${lat}, ${lng}]`);

    document.getElementById('v-name').innerText = alert.victim_name;
    document.getElementById('v-phone').innerText = alert.victim_phone || '--';
    document.getElementById('v-trigger').innerText = alert.trigger_type.toUpperCase();
    const batteryVal = alert.battery_pct || 100;
    const batteryEl = document.getElementById('v-battery');
    batteryEl.innerText = `${batteryVal}%`;
    batteryEl.style.color = batteryVal < 20 ? '#FF3B30' : '#FFD60A';
    if (batteryVal < 15) {
        addLog("CRITICAL: VICTIM BATTERY BELOW 15% - GPS UPLINK RISK", "critical");
    }

    const statusEl = document.getElementById('v-status');
    statusEl.innerText = alert.sos_status.toUpperCase();
    statusEl.style.color = alert.sos_status === 'triggered' ? '#FF3B30' : '#34C759';

    document.getElementById('v-emergency-name').innerText = alert.emergency_contact_name || 'NOT SPECIFIED';
    document.getElementById('v-emergency-phone').innerText = alert.emergency_contact_phone || '--';
    
    // Auto-Acknowledge: If it's just 'triggered', mark as 'in_progress'
    if (alert.sos_status === 'triggered') {
        updateAlertStatus(alert.sos_id, 'in_progress');
    }
    
    document.getElementById('v-time').innerText = new Date(alert.triggered_at).toLocaleTimeString();
    
    document.getElementById('current-lat').innerText = lat.toFixed(4);
    document.getElementById('current-lng').innerText = lng.toFixed(4);

    // Re-calibrate map size after DOM settles
    setTimeout(() => {
        map.invalidateSize();
        map.setView(pos, 15);
    }, 100);

    // Reset tracking path for new selection
    if (trackingPath) map.removeLayer(trackingPath);
    trackingPath = null;
    victimPathPoints = [pos];

    if (victimMarker) map.removeLayer(victimMarker);
    
    // Create pulsing victim marker using CSS
    const victimIcon = L.divIcon({
        className: 'custom-div-icon',
        html: "<div style='background-color:#FF3B30; width:15px; height:15px; border-radius:50%; border:2px solid white; box-shadow: 0 0 10px #FF3B30;' class='marker-pin'></div>",
        iconSize: [15, 15],
        iconAnchor: [7, 7]
    });

    victimMarker = L.marker(pos, { icon: victimIcon }).addTo(map);

    fetchEvidence(alert.sos_id);
    analyzeNearbyStationsAI(alert.latitude, alert.longitude);
    generateAIBriefing(alert);
}

async function analyzeNearbyStationsAI(lat, lng) {
    console.log("KAWACH AI: Searching OpenStreetMap for stations...");
    
    // Overpass API Query for nearby Police Stations
    const query = `[out:json];node["amenity"="police"](around:5000,${lat},${lng});out 3;`;
    const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;

    stationMarkers.forEach(m => map.removeLayer(m));
    stationMarkers = [];

    try {
        const response = await fetch(url);
        const data = await response.json();
        
        if (data.elements && data.elements.length > 0) {
            const stations = data.elements.map(el => {
                const sPos = [el.lat, el.lon];
                const distance = map.distance([lat, lng], sPos) / 1000; // in km
                
                const sMarker = L.marker(sPos, {
                    icon: L.divIcon({
                        className: 'police-icon',
                        html: `<div style='background-color:#007AFF; width:12px; height:12px; border-radius:3px; border:1px solid white;'></div>`,
                        iconSize: [12, 12]
                    })
                }).addTo(map);
                
                sMarker.bindPopup(`<b style="color:black">${el.tags.name || 'Police Station'}</b><br><span style="color:black">${distance.toFixed(2)} km away</span>`);
                stationMarkers.push(sMarker);

                return {
                    name: el.tags.name || 'Local Police Station',
                    distance: distance.toFixed(2),
                    address: el.tags['addr:street'] || 'Nearby coordinates',
                    lat: el.lat,
                    lng: el.lon
                };
            });

            const recommendation = await getGeminiRecommendation(stations, { lat, lng });
            displayAIRecommendation(recommendation);
        }
    } catch (e) {
        console.error("OSM Fetch failed:", e);
    }
}

async function getGeminiRecommendation(stations, pos) {
    const GEMINI_KEY = 'AIzaSyAyClnHz8Ek_lQCTRbXH7MMIuXSzVDJ-_k';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_KEY}`;
    
    const prompt = `You are the Kawach Emergency Dispatch AI. 
    Victim is at coordinates: ${pos.lat}, ${pos.lng}. 
    Nearby Police Stations (with distances in km): ${JSON.stringify(stations)}.
    Pick the absolute best station to respond based on proximity. 
    Return ONLY a JSON object with: { "station_name": "...", "reason": "...", "estimated_response_time": "..." }`;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
        });
        
        if (!response.ok) throw new Error("AI Offline");

        const data = await response.json();
        const text = data.candidates[0].content.parts[0].text;
        return JSON.parse(text.replace(/```json|```/g, ''));
    } catch (e) {
        // FAIL-SAFE: Pure Proximity Rule
        const closest = stations[0];
        return { 
            station_name: closest.name, 
            reason: `Heuristic: Closest available unit (${closest.distance}km). Direct intercept recommended.`, 
            estimated_response_time: `${Math.round(closest.distance * 3 + 2)} mins` 
        };
    }
}

function displayAIRecommendation(rec) {
    const panel = document.getElementById('active-victim-details');
    const aiDiv = document.createElement('div');
    aiDiv.className = 'ai-recommendation';
    aiDiv.innerHTML = `
        <div class="ai-header"><span class="ai-glow"></span> AI SMART ROUTING</div>
        <div class="ai-body">
            <strong>TARGET:</strong> ${rec.station_name}<br>
            <strong>ETA:</strong> ${rec.estimated_response_time}<br>
            <span class="ai-reason">${rec.reason}</span>
        </div>
    `;
    const old = panel.querySelector('.ai-recommendation');
    if (old) old.remove();
    panel.appendChild(aiDiv);
}

async function fetchEvidence(sosId) {
    const { data } = await sb.from('evidence_items').select('*').eq('sos_id', sosId).order('created_at', { ascending: false });
    const feed = document.getElementById('evidence-feed');
    feed.innerHTML = '';
    if (data && data.length > 0) data.forEach(item => renderEvidenceItem(item));
    else feed.innerHTML = '<div class="empty-state">NO MEDIA CAPTURED YET</div>';
}

function renderEvidenceItem(item) {
    const feed = document.getElementById('evidence-feed');
    const card = document.createElement('div');
    card.className = 'evidence-card';
    const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/evidence/${item.storage_path}`;
    
    let content = '';
    if (item.type === 'photo' || item.storage_path.match(/\.(jpg|jpeg|png|webp)$/i)) {
        content = `<img src="${publicUrl}" onerror="this.src='https://placehold.co/400x225/1A1F26/FFFFFF?text=Processing+Media...'">`;
    } else if (item.type === 'audio' || item.storage_path.match(/\.(wav|mp3|m4a)$/i)) {
        content = `
            <div class="audio-evidence">
                <span class="audio-icon">🔊</span>
                <audio controls src="${publicUrl}"></audio>
            </div>
        `;
    } else {
        content = `<div class="file-placeholder">📄 ${item.type.toUpperCase()} CAPTURED</div>`;
    }

    card.innerHTML = `
        ${content}
        <div class="caption">
            TIMESTAMP: ${new Date(item.created_at).toLocaleTimeString()}<br>
            <span style="font-size:0.5rem; color:#007AFF; font-family:monospace;">SIG: ${item.file_hash ? item.file_hash.substring(0, 16) : 'PENDING'}...</span>
        </div>`;
    feed.prepend(card);
}

init();
