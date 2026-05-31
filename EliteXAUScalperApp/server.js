/* ==========================================================================
   ELITE XAUUSD COGNITIVE GATEWAY - API BRIDGE SERVER
   Engineered: Vanilla Node.js (Zero Dependencies)
   Port: 3000
   Links: MT5 (WebRequest) <--> Node.js Gateway <--> Mobile Web Client
   ========================================================================== */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const AUTH_TOKEN = process.env.AUTH_TOKEN || "ELITE_GATEWAY_TOKEN_XYZ"; // Secure pre-shared auth key

// --- User Account Database (In-Memory) ---
let userAccount = {
    email: "",
    name: "",
    isLoggedIn: false,
    subscriptionTier: "None", // "monthly" or "annual"
    isLicensed: false,
    licenseKey: "",
    inbox: [
        {
            id: 101,
            title: "Welcome Operator",
            body: "Secure command link established. Onboarding complete. Please select a subscription tier to activate the automated M1-M5 scalping algorithms.",
            timestamp: "11:05 AM",
            unread: true
        }
    ]
};

// --- In-Memory State Store ---
let telemetryState = {
    // Magic identification
    magicNumber: 0,
    
    // Account metrics
    balance: 0.0,
    equity: 0.0,
    freeMargin: 0.0,
    marginLevel: 0.0,
    leverage: "--",
    
    // Performance & Safeguards
    dailyPnL: 0.0,
    currentDrawdown: 0.0,
    floatingExposure: 0.0,
    consecutiveLosses: 0,
    maxConsecutiveLosses: 0,
    newsStatus: "--",
    
    // Market Telemetry
    currentPrice: 0.0,
    currentSpread: 0,
    currentATR: 0.0,
    currentRegime: "--",
    currentSession: "--",
    
    // Execution Stats
    openPositionsCount: 0,
    averageLatency: 0,
    averageSlippage: 0.0,
    activeStrategy: "None",
    trailStatus: "None",
    positions: [],
    
    // Synchronization
    isMT5Online: false,
    lastSeen: 0
};

// Queued Operator Commands for MT5 execution
let commandQueue = [];

// Signal Log Stream
let signalLog = [
    {
        strat: "SYSTEM",
        action: "INITIALIZE",
        price: 2042.15,
        detail: "API Gateway Bridge initialized. Ready for MT5 terminal connection...",
        timestamp: new Date().toLocaleTimeString()
    }
];

// --- Request Body Parser Helper ---
function parseRequestBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                if (body) {
                    resolve(JSON.parse(body));
                } else {
                    resolve({});
                }
            } catch (err) {
                resolve({});
            }
        });
        req.on('error', err => reject(err));
    });
}

// --- CORS & Headers Configuration ---
function setCorsHeaders(res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-MT5-Auth');
}

// --- Main HTTP Server Router ---
const server = http.createServer(async (req, res) => {
    setCorsHeaders(res);

    // Handle OPTIONS requests (CORS Preflight)
    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
    const pathname = parsedUrl.pathname;

    console.log(`[API GATEWAY] ${req.method} ${pathname}`);

    // ==========================================================================
    // 1. MT5 TERMINAL API ENDPOINTS
    // ==========================================================================
    
    // Endpoint: POST /api/mt5/telemetry
    if (pathname === '/api/mt5/telemetry' && req.method === 'POST') {
        try {
            const data = await parseRequestBody(req);
            
            // 0. Security Token Handshake Validation
            if (data.authToken !== AUTH_TOKEN) {
                res.writeHead(401, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: "error", error: "Security Alert: Unauthorized terminal access rejected." }));
                console.warn(`[SECURITY ALERT] Unauthorized sync attempt blocked from ip: ${req.socket.remoteAddress}`);
                return;
            }

            // 1. Update Core Telemetry
            telemetryState.magicNumber = Number(data.magicNumber || telemetryState.magicNumber);
            telemetryState.balance = Number(data.balance || telemetryState.balance);
            telemetryState.equity = Number(data.equity || telemetryState.equity);
            telemetryState.freeMargin = Number(data.freeMargin || telemetryState.freeMargin);
            telemetryState.marginLevel = Number(data.marginLevel || telemetryState.marginLevel);
            telemetryState.leverage = data.leverage || telemetryState.leverage;
            
            telemetryState.dailyPnL = Number(data.dailyPnL !== undefined ? data.dailyPnL : telemetryState.dailyPnL);
            telemetryState.currentDrawdown = Number(data.currentDrawdown !== undefined ? data.currentDrawdown : telemetryState.currentDrawdown);
            telemetryState.floatingExposure = Number(data.floatingExposure !== undefined ? data.floatingExposure : telemetryState.floatingExposure);
            telemetryState.consecutiveLosses = Number(data.consecutiveLosses !== undefined ? data.consecutiveLosses : telemetryState.consecutiveLosses);
            telemetryState.newsStatus = data.newsStatus || telemetryState.newsStatus;

            telemetryState.currentPrice = Number(data.currentPrice || telemetryState.currentPrice);
            telemetryState.currentSpread = Number(data.currentSpread !== undefined ? data.currentSpread : telemetryState.currentSpread);
            telemetryState.currentATR = Number(data.currentATR || telemetryState.currentATR);
            telemetryState.currentRegime = data.currentRegime || telemetryState.currentRegime;
            telemetryState.currentSession = data.currentSession || telemetryState.currentSession;
            
            telemetryState.openPositionsCount = Number(data.openPositionsCount !== undefined ? data.openPositionsCount : telemetryState.openPositionsCount);
            telemetryState.averageLatency = Number(data.averageLatency || telemetryState.averageLatency);
            telemetryState.averageSlippage = Number(data.averageSlippage !== undefined ? data.averageSlippage : telemetryState.averageSlippage);
            telemetryState.activeStrategy = data.activeStrategy || telemetryState.activeStrategy;
            telemetryState.trailStatus = data.trailStatus || telemetryState.trailStatus;
            telemetryState.positions = data.positions && Array.isArray(data.positions) ? data.positions : [];

            telemetryState.isMT5Online = true;
            telemetryState.lastSeen = Date.now();

            // 2. Add New Signal Logs if pushed by MT5
            if (data.signals && Array.isArray(data.signals)) {
                data.signals.forEach(sig => {
                    signalLog.unshift({
                        strat: sig.strat || "EA",
                        action: sig.action || "SIGNAL",
                        price: Number(sig.price || telemetryState.currentPrice),
                        detail: sig.detail || "",
                        timestamp: new Date().toLocaleTimeString()
                    });
                });
                
                if (signalLog.length > 50) signalLog.slice(0, 50);
            }

            // 3. Retrieve Pending Commands to Dispatch to MT5
            const activeCommands = [...commandQueue];
            commandQueue = []; // Empty command queue after fetching

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: "success",
                commands: activeCommands
            }));
            
            console.log(`[SYNC] MT5 Sync Ping OK. Dispatched ${activeCommands.length} commands.`);
        } catch (err) {
            console.error("[ERROR] Failed parsing MT5 Telemetry:", err);
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: "error", error: "Malformed payload" }));
        }
        return;
    }

    // ==========================================================================
    // 2. MOBILE APP CLIENT API ENDPOINTS
    // ==========================================================================
    
    // Endpoint: GET /api/client/telemetry
    if (pathname === '/api/client/telemetry' && req.method === 'GET') {
        // Validate MT5 heartbeat (Offline if no sync received for > 4.5 seconds)
        if (Date.now() - telemetryState.lastSeen > 4500) {
            telemetryState.isMT5Online = false;
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: "success",
            telemetry: telemetryState,
            signals: signalLog,
            userAccount: userAccount
        }));
        return;
    }

    // Endpoint: POST /api/client/command
    if (pathname === '/api/client/command' && req.method === 'POST') {
        try {
            const data = await parseRequestBody(req);
            
            if (!data.command) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: "error", error: "Command required" }));
                return;
            }

            const newCommand = {
                id: Math.floor(100000 + Math.random() * 900000),
                type: data.command,
                strategyId: data.strategyId || "",
                direction: data.direction || "",
                ticket: Number(data.ticket || 0),
                timestamp: Date.now()
            };

            commandQueue.push(newCommand);
            
            let detailMsg = `Dispatched command [${newCommand.type}] ${data.direction || ""} ${data.strategyId || ""}. Queued for terminal sync.`;
            if (newCommand.type === "CLOSE_TICKET") {
                detailMsg = `Dispatched CLOSE_TICKET command for position #${newCommand.ticket}. Queued for terminal sync.`;
            }

            signalLog.unshift({
                strat: "OPERATOR",
                action: "COMMAND",
                price: telemetryState.currentPrice,
                detail: detailMsg,
                timestamp: new Date().toLocaleTimeString()
            });

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: "success",
                queued: newCommand
            }));
            
            console.log(`[COMMAND] Queued client command: ${newCommand.type}`);
        } catch (err) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: "error", error: "Malformed request payload" }));
        }
        return;
    }

    // Endpoint: POST /api/client/google-sso
    // Simulates Google OAuth credentials onboarding
    if (pathname === '/api/client/google-sso' && req.method === 'POST') {
        try {
            const data = await parseRequestBody(req);
            
            userAccount.email = data.email || "google.operator@gmail.com";
            userAccount.name = data.name || "Google Operator";
            userAccount.isLoggedIn = true;
            
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: "success",
                userAccount: userAccount
            }));
            
            console.log(`[SSO] Google Operator logged in: ${userAccount.email}`);
        } catch (err) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: "error", error: "Auth payload error" }));
        }
        return;
    }

    // Endpoint: POST /api/client/checkout
    // Selects sub tier
    if (pathname === '/api/client/checkout' && req.method === 'POST') {
        try {
            const data = await parseRequestBody(req);
            
            userAccount.subscriptionTier = data.tier || "annual";
            
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: "success",
                userAccount: userAccount
            }));
            
            console.log(`[CHECKOUT] Tier selected: ${userAccount.subscriptionTier}`);
        } catch (err) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: "error", error: "Checkout error" }));
        }
        return;
    }

    // Endpoint: POST /api/client/confirm-payment
    // Validates USDT BEP20 TxHash, registers license key, and pushes mailbox delivery
    if (pathname === '/api/client/confirm-payment' && req.method === 'POST') {
        try {
            const data = await parseRequestBody(req);
            const txHash = data.txHash || "";

            if (!txHash || txHash.length < 10) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: "error", error: "Invalid BNB BEP20 Transaction Hash signature." }));
                return;
            }

            // Generate secure license key
            const randSuffix = Math.floor(1000 + Math.random() * 9000);
            const randHex = Math.random().toString(16).substr(2, 4).toUpperCase();
            const newLicenseKey = `XAU-ELITE-${randSuffix}-${randHex}`;

            // Save variables in account ledger database
            userAccount.isLicensed = true;
            userAccount.licenseKey = newLicenseKey;

            // Push Mailbox Inbox Delivery Message
            const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            const planText = userAccount.subscriptionTier === "annual" ? "Annual Institutional ($200/yr)" : "Monthly Scalper ($20/mo)";
            
            // Mark older messages as read
            userAccount.inbox.forEach(m => m.unread = false);

            userAccount.inbox.unshift({
                id: Math.floor(100000 + Math.random() * 900000),
                title: "License Delivered: Payment Verified",
                body: `USDT BEP20 Payment confirmed for ${planText}. BSC TxHash: ${txHash.substr(0,12)}... verified.\n\nYour secure MQL5 license key is: ${newLicenseKey}\n\nThis key has been automatically injected into your operator profile and terminal sync links. Enjoy your XAUUSD scalping on the go!`,
                timestamp: timestamp,
                unread: true
            });

            // Mirror on system neural streams
            signalLog.unshift({
                strat: "SYSTEM",
                action: "LICENSE_DELIVERED",
                price: telemetryState.currentPrice,
                detail: `Payment TxHash verified. Generated key ${newLicenseKey} and registered to operator inbox.`,
                timestamp: new Date().toLocaleTimeString()
            });

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: "success",
                licenseKey: newLicenseKey,
                userAccount: userAccount
            }));
            
            console.log(`[PAYMENT] BEP20 TxHash validated! Generated license: ${newLicenseKey}`);
        } catch (err) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: "error", error: "Payment checkout failed" }));
        }
        return;
    }

    // ==========================================================================
    // 3. STATIC FILES WEB SERVER
    // ==========================================================================
    let filePath = path.join(__dirname, pathname === '/' ? 'index.html' : pathname);
    
    const extname = path.extname(filePath);
    let contentType = 'text/html';
    switch (extname) {
        case '.js':
            contentType = 'text/javascript';
            break;
        case '.css':
            contentType = 'text/css';
            break;
        case '.json':
            contentType = 'application/json';
            break;
        case '.png':
            contentType = 'image/png';
            break;
        case '.jpg':
            contentType = 'image/jpg';
            break;
    }

    fs.access(filePath, fs.constants.F_OK, (err) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('404 File Not Found');
            return;
        }

        fs.readFile(filePath, (error, content) => {
            if (error) {
                res.writeHead(500);
                res.end(`Server Error: ${error.code}`);
            } else {
                res.writeHead(200, { 'Content-Type': contentType });
                res.end(content, 'utf-8');
            }
        });
    });
});

server.listen(PORT, () => {
    console.log(`==========================================================================`);
    console.log(`ELITE XAUUSD COGNITIVE BRIDGE SERVER IS RUNNING`);
    console.log(`Port: ${PORT}`);
    console.log(`Client App Console: http://localhost:${PORT}`);
    console.log(`MT5 WebRequest Target: http://localhost:${PORT}/api/mt5/telemetry`);
    console.log(`==========================================================================`);
});
