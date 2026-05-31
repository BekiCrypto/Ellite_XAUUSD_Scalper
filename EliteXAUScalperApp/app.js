/* ==========================================================================
   ELITE XAUUSD COGNITIVE MOBILE COMMAND CENTER - CONTROLLER
   Coordinates: Onboarding, SSO, USDT Payments, Mailbox, and MT5 Sync Links
   ========================================================================== */

// --- Persistent Application State (Local cache matched with server databases) ---
let operatorName = localStorage.getItem("operatorName") || "";
let operatorEmail = localStorage.getItem("operatorEmail") || "";
let isLicensed = localStorage.getItem("isLicensed") === "true";
let isMT5Connected = localStorage.getItem("isMT5Connected") === "true";
let subscriptionTier = localStorage.getItem("subscriptionTier") || "None";

let mt5Server = localStorage.getItem("mt5Server") || "ICMarkets-MT5-Live";
let mt5Login = localStorage.getItem("mt5Login") || "8829410";
let mt5Leverage = localStorage.getItem("mt5Leverage") || "1:500";

// --- Global UI Rendering State ---
let balance = 0.00;
let equity = 0.00;
let freeMargin = 0.00;
let marginLevel = 0.0;
let currentPrice = 0.00;
let consecutiveLosses = 0;
let maxConsecutiveLosses = 0;
let activePositionsCount = 0;
let isEnginePaused = false;
let tickIntervalId = null;

// Strategy Enable States (local track)
const strategyState = {
    TP: true,
    MB: true,
    LS: true,
    SE: true,
    MR: true,
    OB: true
};

// Market context parameters
let currentRegime = "--";
let currentSession = "--";
let currentSpread = 0;
let currentATR = 0.0;
let averageLatency = 0;
let averageSlippage = 0.0;
let newsStatus = "--";
let dailyPnL = 0.0;
let currentDrawdown = 0.0;
let floatingExposure = 0.0;
let activeStrategy = "None";
let trailStatus = "None";

// Historical prices for chart plotting
const priceHistory = [];
const maxChartPoints = 30;

// Chart Rendering Canvas
let canvas, ctx;

// --- Initialization & Flow Control ---
window.onload = function() {
    // Setup Canvas Chart
    canvas = document.getElementById("liveChart");
    ctx = canvas.getContext("2d");
    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);

    // Set interactive clock
    updateClock();
    setInterval(updateClock, 1000);

    // Initial State Router
    runStateRouter();
};

function runStateRouter() {
    // 1. If not logged in
    if (!operatorEmail) {
        showScreenView("view-splash");
        animateSplashLoader(() => {
            showScreenView("view-auth");
        });
    }
    // 2. Logged in but has not chosen subscription tier
    else if (subscriptionTier === "None") {
        showScreenView("view-splash");
        animateSplashLoader(() => {
            showScreenView("view-tiers");
        });
    }
    // 3. Subscription selected but has not checked out USDT / activated license
    else if (!isLicensed) {
        showScreenView("view-splash");
        animateSplashLoader(() => {
            setupCheckoutView();
            showScreenView("view-checkout");
        });
    }
    // 4. Subscribed, licensed, but MT5 terminal not synced
    else if (!isMT5Connected) {
        showScreenView("view-splash");
        animateSplashLoader(() => {
            showScreenView("view-mt5");
            renderDynamicWhitelistUrl();
        });
    }
    // 5. Fully synced active cockpit
    else {
        showScreenView("view-splash");
        animateSplashLoader(() => {
            showScreenView("view-app");
            initializeTradingEngine();
        });
    }
}

// --- Screen View Transition Helper ---
function showScreenView(viewId) {
    const screens = document.querySelectorAll(".screen-view");
    screens.forEach(s => s.classList.remove("active"));
    
    const target = document.getElementById(viewId);
    if(target) {
        target.classList.add("active");
    }
}

// --- Clock Simulator ---
function updateClock() {
    const now = new Date();
    const hrs = String(now.getHours()).padStart(2, '0');
    const mins = String(now.getMinutes()).padStart(2, '0');
    const clockEl = document.getElementById("mock-clock");
    if(clockEl) {
        clockEl.innerText = `${hrs}:${mins}`;
    }
}

// --- Splash Screen Simulated Progress ---
function animateSplashLoader(onComplete) {
    const bar = document.getElementById("splash-bar");
    const statusText = document.getElementById("splash-status-text");
    if(!bar) {
        if(onComplete) onComplete();
        return;
    }

    let progress = 0;
    const stages = [
        "Decrypting secure gateway...",
        "Establishing handshakes...",
        "Verifying operator keys...",
        "Link ready. Loading terminal..."
    ];

    bar.style.width = "0%";
    
    const interval = setInterval(() => {
        progress += 4;
        bar.style.width = progress + "%";
        
        if (progress === 24) statusText.innerText = stages[0];
        if (progress === 52) statusText.innerText = stages[1];
        if (progress === 76) statusText.innerText = stages[2];
        if (progress === 92) statusText.innerText = stages[3];

        if (progress >= 100) {
            clearInterval(interval);
            setTimeout(() => {
                if(onComplete) onComplete();
            }, 300);
        }
    }, 40);
}

// ==========================================================================
// ONBOARDING & AUTHENTICATION FLOWS
// ==========================================================================
function switchAuthTab(tab) {
    const btnSignin = document.getElementById("btn-tab-signin");
    const btnSignup = document.getElementById("btn-tab-signup");
    const formSignin = document.getElementById("form-signin");
    const formSignup = document.getElementById("form-signup");

    if (tab === "signin") {
        btnSignin.classList.add("active");
        btnSignup.classList.remove("active");
        formSignin.classList.add("active");
        formSignup.classList.remove("active");
    } else {
        btnSignup.classList.add("active");
        btnSignin.classList.remove("active");
        formSignup.classList.add("active");
        formSignin.classList.remove("active");
    }
}

// --- Backup card authentication ---
function handleAuth(type) {
    if (type === 'signin') {
        const email = document.getElementById("signin-email").value.trim();
        const pass = document.getElementById("signin-pass").value.trim();

        if (!email || !pass) {
            alert("Security Alert: Operator credentials cannot be empty.");
            return;
        }

        operatorEmail = email;
        operatorName = "Beki Operator";
    } else {
        const name = document.getElementById("signup-name").value.trim();
        const email = document.getElementById("signup-email").value.trim();
        const pass = document.getElementById("signup-pass").value.trim();

        if (!name || !email || !pass) {
            alert("Security Alert: Form incomplete. Please define name, email, and passcode.");
            return;
        }

        operatorName = name;
        operatorEmail = email;
    }

    localStorage.setItem("operatorName", operatorName);
    localStorage.setItem("operatorEmail", operatorEmail);
    
    // Post to server database
    fetch('/api/client/google-sso', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: operatorEmail, name: operatorName })
    })
    .then(() => {
        showScreenView("view-tiers");
    });
}

// --- Google SSO OAuth Simulation ---
function handleGoogleSSO() {
    const overlay = document.getElementById("sso-loading-overlay");
    overlay.classList.add("active");

    setTimeout(() => {
        operatorName = "Alex Scalper";
        operatorEmail = "alex.scalper@gmail.com";

        localStorage.setItem("operatorName", operatorName);
        localStorage.setItem("operatorEmail", operatorEmail);

        // Sync with API Gateway
        fetch('/api/client/google-sso', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: operatorEmail, name: operatorName })
        })
        .then(res => res.json())
        .then(data => {
            overlay.classList.remove("active");
            showScreenView("view-tiers");
        })
        .catch(err => {
            overlay.classList.remove("active");
            alert("SSO Connection failed. Check if server is running.");
        });
    }, 1800); // Premium login delay
}

// ==========================================================================
// MONETIZATION TIER & CRYPTO CHECKOUT FLOW
// ==========================================================================
function selectSubscription(tier) {
    // UI Feedback active toggle
    const monthlyCard = document.getElementById("tier-monthly");
    const annualCard = document.getElementById("tier-annual");

    if (tier === "monthly") {
        monthlyCard.classList.add("active");
        annualCard.classList.remove("active");
    } else {
        annualCard.classList.add("active");
        monthlyCard.classList.remove("active");
    }

    subscriptionTier = tier;
    localStorage.setItem("subscriptionTier", subscriptionTier);

    // Sync sub selection with server
    fetch('/api/client/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tier: subscriptionTier })
    })
    .then(res => res.json())
    .then(data => {
        // Move to checkout panel
        setupCheckoutView();
        showScreenView("view-checkout");
    });
}

function setupCheckoutView() {
    const planNameEl = document.getElementById("checkout-plan-name");
    const planPriceEl = document.getElementById("checkout-plan-price");
    
    if (subscriptionTier === "monthly") {
        planNameEl.innerText = "Monthly Scalper Pro";
        planPriceEl.innerText = "20.00 USDT";
    } else {
        planNameEl.innerText = "Annual Institutional Scalp";
        planPriceEl.innerText = "200.00 USDT";
    }

    document.getElementById("checkout-txhash").value = "";
    document.getElementById("checkout-payment-box").style.display = "flex";
    document.getElementById("checkout-blockchain-verifier").style.display = "none";
}

// --- Crypto Clipboard helper ---
function copyWalletAddress() {
    const copyText = document.getElementById("checkout-wallet-address");
    copyText.select();
    copyText.setSelectionRange(0, 99999); // For mobile devices
    
    navigator.clipboard.writeText(copyText.value)
        .then(() => {
            // High fidelity toast notification
            const copyBtn = document.querySelector(".btn-copy");
            const originalIcon = copyBtn.innerHTML;
            copyBtn.innerHTML = '<i class="fa-solid fa-circle-check text-green"></i>';
            setTimeout(() => {
                copyBtn.innerHTML = originalIcon;
            }, 1500);
        })
        .catch(err => {
            console.error("Clipboard write error:", err);
        });
}

// --- USDT BEP20 Payment Validator & Block checker loader ---
function confirmUSDTPayment() {
    const txHash = document.getElementById("checkout-txhash").value.trim();

    if (!txHash || txHash.length < 10) {
        alert("Transaction Blocked: Please paste a valid BEP20 transaction TxID hash.");
        return;
    }

    // Toggle Verifier loaders screen
    const paymentBox = document.getElementById("checkout-payment-box");
    const verifier = document.getElementById("checkout-blockchain-verifier");
    paymentBox.style.display = "none";
    verifier.style.display = "flex";

    const progressBar = document.getElementById("bc-progress-bar");
    const statusText = document.getElementById("verifier-status-text");

    progressBar.style.width = "0%";
    
    const steps = [
        { p: 15, msg: "Broadcasting payment hash to BNB Smart Chain..." },
        { p: 40, msg: "Scanning block indices for transaction address..." },
        { p: 70, msg: "Validating BEP20 Smart Contract token transfers..." },
        { p: 90, msg: "Payment found! Awaiting final block confirmation..." },
        { p: 100, msg: "100% verified. Emitting cognitive engine license..." }
    ];

    let currentStep = 0;
    
    // 3-Second progressive blockchain block checking loop
    const interval = setInterval(() => {
        if(currentStep >= steps.length) {
            clearInterval(interval);
            
            // Execute confirm POST to server
            fetch('/api/client/confirm-payment', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ txHash: txHash })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === "success") {
                    isLicensed = true;
                    localStorage.setItem("isLicensed", "true");
                    localStorage.setItem("licenseKey", data.licenseKey);
                    
                    // Proceed to MT5 Screen
                    setTimeout(() => {
                        showScreenView("view-mt5");
                        renderDynamicWhitelistUrl();
                    }, 50);
                } else {
                    paymentBox.style.display = "flex";
                    verifier.style.display = "none";
                    alert("Verification Rejected: " + data.error);
                }
            })
            .catch(err => {
                paymentBox.style.display = "flex";
                verifier.style.display = "none";
                alert("Blockchain sync error. gateway is down.");
            });
            return;
        }

        const step = steps[currentStep];
        statusText.innerText = step.msg;
        progressBar.style.width = step.p + "%";
        currentStep++;
    }, 600);
}

// ==========================================================================
// FALLBACK MANUAL LICENSE ACTIVATION FLOW
// ==========================================================================
function handleLicenseActivation() {
    const key = document.getElementById("license-key").value.trim();
    
    if(!key) {
        alert("Activation Blocked: Key required to initialize neural engines.");
        return;
    }

    if (key.length < 6) {
        alert("Verification Error: Invalid license signature format.");
        return;
    }

    isLicensed = true;
    localStorage.setItem("isLicensed", "true");
    localStorage.setItem("licenseKey", key);
    showScreenView("view-mt5");
}

// ==========================================================================
// MT5 SERVER SYNC CONNECTION HANDSHAKE FLOW
// ==========================================================================
function handleMT5Connection() {
    const server = document.getElementById("mt5-server").value.trim();
    const login = document.getElementById("mt5-login").value.trim();
    const pass = document.getElementById("mt5-pass").value.trim();
    const leverage = document.getElementById("mt5-leverage").value;

    if (!server || !login || !pass) {
        alert("Terminal Link Blocked: Server, Login Account ID, and Passcodes are mandatory.");
        return;
    }

    mt5Server = server;
    mt5Login = login;
    mt5Leverage = leverage;

    localStorage.setItem("mt5Server", mt5Server);
    localStorage.setItem("mt5Login", mt5Login);
    localStorage.setItem("mt5Leverage", mt5Leverage);

    const setupForm = document.getElementById("mt5-setup-form");
    const syncLoader = document.getElementById("mt5-sync-loader");
    setupForm.style.display = "none";
    syncLoader.style.display = "flex";

    const progressEl = document.getElementById("sync-progress-bar");
    const stageTitle = document.getElementById("sync-stage-title");
    const logList = document.getElementById("sync-steps-log");

    logList.innerHTML = "";
    progressEl.style.width = "0%";

    const steps = [
        { progress: 20, title: "Connecting gateway server...", detail: `Connecting API Gateway at http://localhost:3000...` },
        { progress: 45, title: "Credentials auth...", detail: `Verifying operator login account: #${mt5Login}...` },
        { progress: 70, title: "Handshake verified...", detail: "Waiting for MQL5 expert connector ping..." },
        { progress: 100, title: "Synchronized Successfully", detail: "Terminal link connected! Listening for incoming MT5 WebRequests..." }
    ];

    let currentStep = 0;

    function runNextStep() {
        if(currentStep >= steps.length) {
            setTimeout(() => {
                isMT5Connected = true;
                localStorage.setItem("isMT5Connected", "true");
                showScreenView("view-app");
                initializeTradingEngine();
            }, 800);
            return;
        }

        const step = steps[currentStep];
        stageTitle.innerText = step.title;
        progressEl.style.width = step.progress + "%";

        const li = document.createElement("li");
        if(step.progress === 100) {
            li.className = "success";
            li.innerHTML = `<i class="fa-solid fa-circle-check"></i> ${step.detail}`;
        } else {
            li.className = "pending";
            li.innerHTML = `<i class="fa-solid fa-circle-notch fa-spin"></i> ${step.detail}`;
        }
        logList.appendChild(li);
        logList.scrollTop = logList.scrollHeight;

        if (currentStep > 0) {
            const items = logList.getElementsByTagName("li");
            const prevItem = items[currentStep - 1];
            if(prevItem) {
                prevItem.className = "success";
                prevItem.innerHTML = `<i class="fa-solid fa-circle-check"></i> ${steps[currentStep-1].detail}`;
            }
        }

        currentStep++;
        const delay = 600 + Math.random() * 400;
        setTimeout(runNextStep, delay);
    }

    runNextStep();
}

// ==========================================================================
// CORE TRADING INTEGRATION & CHART RENDERING
// ==========================================================================
function initializeTradingEngine() {
    // Fill dynamic labels in Profile
    document.getElementById("profile-operator-name").innerText = operatorName;
    document.getElementById("profile-operator-email").innerText = operatorEmail;
    document.getElementById("profile-mt5-server").innerText = mt5Server;
    document.getElementById("profile-mt5-id").innerText = mt5Login;

    // Reset previous loop if exists
    if(tickIntervalId) clearInterval(tickIntervalId);

    // Initial render
    resizeCanvas();
    onTick(); // First sync execution

    // Run active API polling timer loop (every 1.0 second)
    tickIntervalId = setInterval(onTick, 1000);
}

function resizeCanvas() {
    if(!canvas) return;
    canvas.width = canvas.parentElement.clientWidth;
    canvas.height = canvas.parentElement.clientHeight;
    drawChart();
}

// --- Active Telemetry Polling via API Bridge ---
function onTick() {
    if(!isMT5Connected) return;

    fetch('/api/client/telemetry')
        .then(response => response.json())
        .then(data => {
            if (data.status === "success") {
                const tel = data.telemetry;
                const user = data.userAccount;

                // 1. Sync User / Licensing parameters
                if (user) {
                    operatorName = user.name;
                    operatorEmail = user.email;
                    isLicensed = user.isLicensed;
                    subscriptionTier = user.subscriptionTier;

                    document.getElementById("profile-lic-key").innerText = user.licenseKey || "None";
                    
                    const tierLabel = subscriptionTier === "annual" ? "Annual Institutional ($200/yr)" : (subscriptionTier === "monthly" ? "Monthly Scalper Pro ($20/mo)" : "None");
                    document.getElementById("profile-sub-tier").innerText = tierLabel;
                    
                    const statusBadge = document.getElementById("profile-lic-status");
                    if (isLicensed) {
                        statusBadge.innerText = "LICENSED";
                        statusBadge.className = "profile-status-badge text-gold";
                    } else {
                        statusBadge.innerText = "EXPIRED";
                        statusBadge.className = "profile-status-badge text-red";
                    }

                    // Render operator Mailbox
                    renderMailboxMessages(user.inbox);
                }

                // 2. Update prices & chart paths
                const oldPrice = currentPrice;
                currentPrice = tel.currentPrice;

                if (currentPrice > 0 && currentPrice !== priceHistory[priceHistory.length - 1]) {
                    priceHistory.push(currentPrice);
                    if (priceHistory.length > maxChartPoints) {
                        priceHistory.shift();
                    }
                }

                // 3. Load broker statistics variables
                if (tel.magicNumber && tel.magicNumber > 0) {
                    document.getElementById("app-header-magic").innerText = "Magic: " + tel.magicNumber;
                } else {
                    document.getElementById("app-header-magic").innerText = "Magic: Standby";
                }
                balance = tel.balance;
                equity = tel.equity;
                freeMargin = tel.freeMargin;
                marginLevel = tel.marginLevel;
                mt5Leverage = tel.leverage;

                dailyPnL = tel.dailyPnL;
                currentDrawdown = tel.currentDrawdown;
                floatingExposure = tel.floatingExposure;
                consecutiveLosses = tel.consecutiveLosses;
                newsStatus = tel.newsStatus;

                currentSpread = tel.currentSpread;
                currentATR = tel.currentATR;
                currentRegime = tel.currentRegime;
                currentSession = tel.currentSession;

                activePositionsCount = tel.openPositionsCount;
                averageLatency = tel.averageLatency;
                averageSlippage = tel.averageSlippage;
                activeStrategy = tel.activeStrategy;
                trailStatus = tel.trailStatus;

                // 4. Render prices pills
                const pricePill = document.getElementById("mobile-price-pill");
                const trendIcon = document.getElementById("price-trend-icon");
                
                if (currentPrice > 0) {
                    document.getElementById("live-price").innerText = "$" + currentPrice.toFixed(2);
                    if (oldPrice === 0 || currentPrice >= oldPrice) {
                        pricePill.className = "price-pill up";
                        trendIcon.className = "fa-solid fa-circle-chevron-up";
                    } else {
                        pricePill.className = "price-pill down";
                        trendIcon.className = "fa-solid fa-circle-chevron-down";
                    }
                } else {
                    document.getElementById("live-price").innerText = "$0.00";
                    pricePill.className = "price-pill";
                    trendIcon.className = "fa-solid fa-circle-notch fa-spin";
                }

                // 5. Update sync status pill based on server heartbeat
                const syncLabel = document.querySelector(".sync-label");
                const pulseDot = document.querySelector(".pulse-dot");
                
                if (tel.isMT5Online) {
                    syncLabel.innerText = "SYNCED";
                    syncLabel.style.color = "var(--color-green)";
                    pulseDot.className = "pulse-dot";
                    pulseDot.style.backgroundColor = "var(--color-green)";
                    pulseDot.style.boxShadow = "0 0 6px var(--color-green)";
                } else {
                    syncLabel.innerText = "STANDBY";
                    syncLabel.style.color = "var(--color-orange)";
                    pulseDot.className = "pulse-dot";
                    pulseDot.style.backgroundColor = "var(--color-orange)";
                    pulseDot.style.boxShadow = "0 0 6px var(--color-orange)";
                }

                // 6. Render logs signal stream list
                renderSignalStreamLogs(data.signals);

                // Render live open positions
                renderLivePositionsList(tel.positions);

                // 7. Draw UI
                drawChart();
                updateDashboardUI();
            }
        })
        .catch(err => {
            console.warn("API Bridge Sync Standby: Connection down.", err);
            const syncLabel = document.querySelector(".sync-label");
            const pulseDot = document.querySelector(".pulse-dot");
            if (syncLabel) {
                syncLabel.innerText = "DISCONNECTED";
                syncLabel.style.color = "var(--color-red)";
                pulseDot.style.backgroundColor = "var(--color-red)";
                pulseDot.style.boxShadow = "0 0 6px var(--color-red)";
            }
        });
}

// --- Canvas chart plotter ---
function drawChart() {
    if(!ctx || !canvas) return;
    
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    if(priceHistory.length === 0) {
        ctx.fillStyle = "rgba(255, 255, 255, 0.4)";
        ctx.font = "12px 'Outfit'";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("Awaiting terminal price stream...", canvas.width / 2, canvas.height / 2);
        return;
    }
    
    // Draw grid
    ctx.strokeStyle = "rgba(60, 80, 110, 0.04)";
    ctx.lineWidth = 1;
    const gridCols = 6;
    const gridRows = 4;
    
    for(let i=0; i<gridCols; i++) {
        const x = (canvas.width / gridCols) * i;
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.stroke();
    }
    for(let i=0; i<gridRows; i++) {
        const y = (canvas.height / gridRows) * i;
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(canvas.width, y);
        ctx.stroke();
    }

    const minVal = Math.min(...priceHistory) - 1.2;
    const maxVal = Math.max(...priceHistory) + 1.2;
    const range = maxVal - minVal;

    // Draw Price lines
    ctx.beginPath();
    ctx.strokeStyle = "rgba(70, 160, 240, 0.9)";
    ctx.lineWidth = 2.5;
    ctx.shadowBlur = 8;
    ctx.shadowColor = "rgba(70, 160, 240, 0.4)";
    
    for(let i=0; i<priceHistory.length; i++) {
        const x = (canvas.width / (priceHistory.length - 1)) * i;
        const y = canvas.height - ((priceHistory[i] - minVal) / range) * canvas.height;
        if(i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Draw fill areas
    ctx.beginPath();
    const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
    gradient.addColorStop(0, "rgba(70, 160, 240, 0.12)");
    gradient.addColorStop(1, "rgba(70, 160, 240, 0.0)");
    ctx.fillStyle = gradient;
    
    for(let i=0; i<priceHistory.length; i++) {
        const x = (canvas.width / (priceHistory.length - 1)) * i;
        const y = canvas.height - ((priceHistory[i] - minVal) / range) * canvas.height;
        if(i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.lineTo(canvas.width, canvas.height);
    ctx.lineTo(0, canvas.height);
    ctx.closePath();
    ctx.fill();
}

// --- UI Telemetry Dashboard Sync ---
function updateDashboardUI() {
    // 1. Account Metrics
    document.getElementById("db-balance").innerText = balance > 0 ? "$" + balance.toFixed(2) : "$0.00";
    document.getElementById("db-equity").innerText = equity > 0 ? "$" + equity.toFixed(2) : "$0.00";
    document.getElementById("db-margin").innerText = freeMargin > 0 ? "$" + freeMargin.toFixed(2) + " (" + marginLevel.toFixed(0) + "%)" : "$0.00 (0%)";
    
    // Profile sync
    const profileLatency = document.getElementById("profile-mt5-latency");
    if(profileLatency) profileLatency.innerText = averageLatency > 0 ? averageLatency + " ms" : "--";
    
    const profileLeverage = document.getElementById("profile-mt5-leverage");
    if(profileLeverage) profileLeverage.innerText = mt5Leverage || "--";

    // 2. Risk Metrics
    const pnlSign = dailyPnL > 0 ? "+" : "";
    document.getElementById("db-daily-profit").innerText = dailyPnL !== 0 ? `${pnlSign}${dailyPnL.toFixed(2)}%` : "0.00%";
    document.getElementById("db-daily-profit").className = `val ${dailyPnL > 0 ? "text-green" : (dailyPnL < 0 ? "text-red" : "")}`;
    
    document.getElementById("db-losses").innerText = maxConsecutiveLosses > 0 ? `${consecutiveLosses} / ${maxConsecutiveLosses}` : "0 / 0";
    document.getElementById("db-losses").className = `val ${consecutiveLosses >= maxConsecutiveLosses && maxConsecutiveLosses > 0 ? "text-red" : (consecutiveLosses > 0 ? "text-orange" : "")}`;
    
    document.getElementById("db-daily-dd").innerText = `${currentDrawdown.toFixed(2)}%`;
    document.getElementById("db-daily-dd").className = `val ${currentDrawdown > 3.0 ? "text-red" : (currentDrawdown > 0 ? "text-orange" : "text-green")}`;

    // Exposure
    const pipsSign = floatingExposure > 0 ? "+" : "";
    document.getElementById("db-exposure").innerText = floatingExposure !== 0 ? `${pipsSign}${floatingExposure.toFixed(1)} pips (${activePositionsCount})` : `0.0 pips (0)`;
    document.getElementById("db-exposure").className = `val ${floatingExposure > 0 ? "text-green" : (floatingExposure < 0 ? "text-red" : "")}`;

    const newsShield = document.getElementById("db-news-status");
    newsShield.innerText = newsStatus || "--";
    newsShield.className = `status-pill ${newsStatus === "CLEAR" ? "clear" : (newsStatus === "--" ? "" : "text-red")}`;

    // Market session details
    document.getElementById("val-session").innerText = currentSession || "--";
    document.getElementById("val-regime").innerText = currentRegime || "--";
    document.getElementById("val-spread").innerText = currentSpread > 0 ? currentSpread + " pts" : "0 pts";
}

// ==========================================================================
// TABS SWITCHING ROUTERS
// ==========================================================================
function switchMainTab(tab) {
    const buttons = document.querySelectorAll(".nav-tab-btn");
    buttons.forEach(b => b.classList.remove("active"));

    const panes = document.querySelectorAll(".tab-pane");
    panes.forEach(p => p.classList.remove("active"));

    document.getElementById("nav-btn-" + tab).classList.add("active");

    const targetPane = document.getElementById("pane-" + tab);
    if(targetPane) {
        targetPane.classList.add("active");
    }

    if (tab === "dashboard") {
        setTimeout(resizeCanvas, 50);
    }
}

// ==========================================================================
// CLIENT GATEWAY UPLINK COMMANDS HANDLERS
// ==========================================================================
function sendClientCommand(commandType, extraData = {}) {
    fetch('/api/client/command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: commandType,
            ...extraData
        })
    })
    .then(res => res.json())
    .then(data => {
        if(data.status === "success") {
            console.log(`[CLIENT] Command dispatched: [${commandType}]`);
            onTick();
        }
    })
    .catch(err => console.error("API bridge command post error:", err));
}

function toggleStrategy(stratId) {
    strategyState[stratId] = !strategyState[stratId];
    const btn = document.getElementById("toggle-" + stratId);
    
    if(strategyState[stratId]) {
        btn.className = "strat-btn-mobile active";
    } else {
        btn.className = "strat-btn-mobile";
    }
    
    sendClientCommand("STRATEGY_TOGGLE", { strategyId: stratId });
}

function manualTrade(direction) {
    sendClientCommand("MANUAL_TRADE", { direction: direction });
}

function triggerBreakEven() {
    sendClientCommand("MOVE_BE");
}

function toggleEnginePause() {
    isEnginePaused = !isEnginePaused;
    const btn = document.getElementById("btn-pause");
    
    if (isEnginePaused) {
        btn.innerHTML = '<i class="fa-solid fa-play"></i> RESUME ENGINE';
        btn.className = "btn-secondary-mobile active";
    } else {
        btn.innerHTML = '<i class="fa-solid fa-pause"></i> PAUSE ENGINE';
        btn.className = "btn-secondary-mobile";
    }
    
    sendClientCommand("PAUSE_TOGGLE");
}

function panicCloseAll() {
    sendClientCommand("PANIC_CLOSE");
}

function closeSpecificPosition(ticket) {
    if(confirm(`Confirm emergency liquidation of position #${ticket}?`)) {
        sendClientCommand("CLOSE_TICKET", { ticket: ticket });
    }
}

// --- Render Live Open Positions in Cockpit ---
function renderLivePositionsList(positions) {
    const listEl = document.getElementById("db-positions-list");
    const countBadge = document.getElementById("db-positions-badge");
    if(!listEl) return;

    const count = positions ? positions.length : 0;
    if (countBadge) {
        countBadge.innerText = `${count} Active`;
    }

    if (!positions || positions.length === 0) {
        listEl.innerHTML = `
            <div class="empty-state-small">
                <i class="fa-solid fa-folder-open"></i>
                <p>No open positions in active terminal</p>
            </div>`;
        return;
    }

    listEl.innerHTML = "";
    positions.forEach(pos => {
        const row = document.createElement("div");
        row.className = "position-row";
        
        const isBuy = pos.type === 0 || pos.type === "POSITION_TYPE_BUY" || String(pos.type).toUpperCase().indexOf("BUY") >= 0;
        const typeLabel = isBuy ? "BUY" : "SELL";
        const typeClass = isBuy ? "buy" : "sell";
        
        const profitVal = Number(pos.profit);
        const profitClass = profitVal >= 0 ? "text-green" : "text-red";
        const profitSign = profitVal >= 0 ? "+" : "";

        row.innerHTML = `
            <div class="pos-main-info">
                <div class="pos-left">
                    <span class="pos-type-tag ${typeClass}">${typeLabel}</span>
                    <span class="pos-symbol">${pos.symbol}</span>
                    <span class="pos-volume">${pos.volume.toFixed(2)} Lots</span>
                </div>
                <div class="pos-profit-wrap">
                    <span class="pos-profit ${profitClass}">${profitSign}$${profitVal.toFixed(2)}</span>
                </div>
            </div>
            <div class="pos-details-info">
                <div class="pos-prices">
                    Entry: <span>${pos.priceOpen.toFixed(2)}</span> &rarr; Bid: <span>${pos.priceCurrent.toFixed(2)}</span>
                </div>
                <button class="btn-close-pos" onclick="closeSpecificPosition(${pos.ticket})">
                    <i class="fa-solid fa-circle-xmark"></i> CLOSE
                </button>
            </div>
        `;
        listEl.appendChild(row);
    });
}

// --- Signals Logs Stream Renderer ---
function renderSignalStreamLogs(signals) {
    const stream = document.getElementById("signalStream");
    if(!stream) return;

    if(!signals || signals.length === 0) {
        stream.innerHTML = `
            <div class="empty-state">
                <i class="fa-solid fa-wave-square"></i>
                <p>Waiting for algorithm signals...</p>
            </div>`;
        return;
    }

    stream.innerHTML = "";
    
    signals.forEach(sig => {
        const item = document.createElement("div");
        const act = sig.action.toUpperCase();
        item.className = `signal-item ${act === "BUY" ? "buy" : (act === "SELL" ? "sell" : "")}`;
        
        let badgeClass = "badge-charcoal";
        if (act === "BUY") badgeClass = "text-green";
        else if (act === "SELL") badgeClass = "text-red";
        else if (act === "TRADE_CLOSED") badgeClass = "text-orange";
        else if (act === "COMMAND") badgeClass = "text-cyan";
        else if (act === "LICENSE_DELIVERED") badgeClass = "text-gold";

        item.innerHTML = `
            <div class="signal-info">
                <span class="strat">${sig.strat}</span>
                <span class="action ${badgeClass}">${act}</span>
            </div>
            <div class="signal-details">
                <p>${sig.detail}</p>
            </div>
            <div class="signal-levels">
                <span class="price">$${sig.price.toFixed(2)}</span>
                <span class="sl-tp">${sig.timestamp}</span>
            </div>
        `;
        stream.appendChild(item);
    });

    const activeCountBadge = document.getElementById("signal-count");
    if(activeCountBadge) {
        activeCountBadge.innerText = activePositionsCount + " Active";
    }
}

// --- Mailbox Inbox Feed Renderer ---
function renderMailboxMessages(inbox) {
    const listEl = document.getElementById("mailbox-list");
    if(!listEl) return;

    if(!inbox || inbox.length === 0) {
        listEl.innerHTML = '<p class="input-tip" style="text-align:center;">Secure mailbox empty</p>';
        return;
    }

    // Render list
    listEl.innerHTML = "";
    inbox.forEach(msg => {
        const msgCard = document.createElement("div");
        msgCard.className = `mailbox-message ${msg.unread ? "unread" : ""}`;
        
        msgCard.innerHTML = `
            <h4>${msg.title}</h4>
            <p>${msg.body.replace(/\n/g, "<br>")}</p>
            <span class="m-time">${msg.timestamp}</span>
        `;
        listEl.appendChild(msgCard);
    });
}

// ==========================================================================
// TERMINAL DISCONNECT & DE-REGISTRATION
// ==========================================================================
function disconnectTerminal() {
    isMT5Connected = false;
    localStorage.removeItem("isMT5Connected");
    
    if(tickIntervalId) clearInterval(tickIntervalId);

    const setupForm = document.getElementById("mt5-setup-form");
    const syncLoader = document.getElementById("mt5-sync-loader");
    setupForm.style.display = "flex";
    syncLoader.style.display = "none";

    showScreenView("view-mt5");
}

function revokeLicense() {
    isMT5Connected = false;
    isLicensed = false;
    subscriptionTier = "None";
    
    localStorage.removeItem("isMT5Connected");
    localStorage.removeItem("isLicensed");
    localStorage.removeItem("subscriptionTier");
    localStorage.removeItem("licenseKey");
    
    if(tickIntervalId) clearInterval(tickIntervalId);

    const setupForm = document.getElementById("mt5-setup-form");
    const syncLoader = document.getElementById("mt5-sync-loader");
    setupForm.style.display = "flex";
    syncLoader.style.display = "none";

    showScreenView("view-tiers");
}

// --- Dynamic MT5 Whitelisting Helper Functions ---
function renderDynamicWhitelistUrl() {
    const whUrlEl = document.getElementById("mt5-wh-url");
    if (whUrlEl) {
        const protocol = "http://";
        const host = window.location.hostname || "127.0.0.1";
        const port = window.location.port ? ":" + window.location.port : "";
        whUrlEl.innerText = `${protocol}${host}${port}`;
    }
}

function copyWhitelistUrl() {
    const whUrlEl = document.getElementById("mt5-wh-url");
    if (!whUrlEl) return;
    
    navigator.clipboard.writeText(whUrlEl.innerText)
        .then(() => {
            const copyBtn = document.querySelector(".btn-copy-wh");
            const originalIcon = copyBtn.innerHTML;
            copyBtn.innerHTML = '<i class="fa-solid fa-check text-green"></i>';
            setTimeout(() => {
                copyBtn.innerHTML = originalIcon;
            }, 1500);
        })
        .catch(err => console.error("Whitelist clipboard error:", err));
}
