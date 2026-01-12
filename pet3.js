// ========================================
// API & GLOBALS
// ========================================
const API_BASE = "http://127.0.0.1:8000/api";
let currentUser = null;
let token = localStorage.getItem("paw_token");

// ========================================
// GLOBAL HELPERS (Hoisted)
// ========================================
function logout() {
    token = null;
    currentUser = null;
    localStorage.removeItem("paw_token");
    document.getElementById("nav-logged-in")?.classList.add("hidden");
    document.getElementById("nav-logged-out")?.classList.remove("hidden");
    showScreen("welcome-screen");
}

// Expose to window for inline HTML calls if needed
window.logout = logout;

function showScreen(screenId) {
    document.querySelectorAll(".screen").forEach((s) => s.classList.add("hidden"));
    document.getElementById(screenId)?.classList.remove("hidden");
}

function showModal(modalId) {
    document.getElementById("modal-overlay").classList.remove("hidden");
    document.getElementById(modalId)?.classList.remove("hidden");
}

function hideAllModals() {
    document.getElementById("modal-overlay").classList.add("hidden");
    document.querySelectorAll(".modal").forEach((m) => m.classList.add("hidden"));
}

function updateUIForUser() {
    if (currentUser) {
        document.getElementById("nav-logged-out")?.classList.add("hidden");
        document.getElementById("nav-logged-in")?.classList.remove("hidden");
        const welcomeMsg = document.getElementById("welcome-message");
        if (welcomeMsg) welcomeMsg.textContent = `Hola, ${currentUser.email}`;
    }
}

function navigateBasedOnRole() {
    console.log("Navegando según rol:", currentUser);
    if (!currentUser) {
        console.warn("No hay usuario actual, regresando a welcome");
        showScreen("welcome-screen");
        return;
    }

    const type = (currentUser.rol || "").toLowerCase();
    console.log("Rol detectado (normalized):", type);

    if (type === "fundacion") {
        console.log("Mostrando pantalla fundación");
        showScreen("fundacion-screen");
        if (typeof window.renderFundacionScreen === 'function') window.renderFundacionScreen();
    } else if (type === "adoptante") {
        console.log("Mostrando pantalla adoptante");
        showScreen("adoptante-screen");
        if (typeof window.renderAdoptanteScreen === 'function') window.renderAdoptanteScreen();
    } else {
        console.error("Rol desconocido:", currentUser.rol);
        alert("Error: Rol de usuario desconocido");
    }
}

// ========================================
// API HELPERS
// ========================================
async function apiCall(endpoint, method = "GET", body = null) {
    const headers = {
        "Content-Type": "application/json",
    };
    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    const config = {
        method,
        headers,
    };

    if (body) {
        config.body = JSON.stringify(body);
    }

    try {
        const res = await fetch(`${API_BASE}${endpoint}`, config);
        if (res.status === 401) {
            logout(); // Now defined!
            throw new Error("Sesión expirada");
        }
        const data = await res.json();
        if (!res.ok) {
            throw new Error(data.detail || "Error en API");
        }
        return data;
    } catch (err) {
        console.error("API Error:", err);
        throw err;
    }
}

document.addEventListener("DOMContentLoaded", async () => {
    console.log("DOM Cargado - Inicializando Listeners...");

    // ========================================
    // GLOBAL EVENT DELEGATION (The "Silver Bullet" fix)
    // ========================================
    document.addEventListener("click", (e) => {
        const target = e.target;
        const id = target.id;

        // Navigation
        if (id === "show-register-btn" || id === "footer-go-to-register") {
            e.preventDefault();
            showScreen("register-screen");
        }
        else if (id === "show-login-btn" || id === "footer-go-to-login") {
            e.preventDefault();
            showScreen("login-screen");
        }
        else if (id === "back-to-welcome-btn" || id === "back-to-welcome-btn-2") {
            e.preventDefault();
            showScreen("welcome-screen");
        }
        else if (id === "nav-home") {
            e.preventDefault();
            navigateBasedOnRole();
        }
        else if (id === "nav-logout") {
            e.preventDefault();
            token = null; // Ensure token is cleared effectively
            logout();
        }

        // Adoptante Actions
        else if (id === "apply-filters-btn") {
            e.preventDefault();
            const species = document.getElementById("filter-species")?.value;
            console.log("Aplicando filtros:", species);
            renderPetsGrid({ species });
        }
        else if (id === "complete-profile-btn") {
            e.preventDefault();
            showModal("modal-profile");
        }

        // Fundacion Actions
        else if (id === "btn-add-empleado") {
            e.preventDefault();
            showModal("modal-empleado");
        }
        else if (id === "add-pet-btn") {
            e.preventDefault();
            showModal("modal-pet-form");
        }
        else if (id === "btn-open-rescate-modal") {
            e.preventDefault();
            showModal("modal-rescate");
        }
        else if (id === "btn-open-lista-negra-modal") {
            e.preventDefault();
            showModal("modal-lista-negra");
        }
        else if (id === "btn-open-cita-modal") {
            const idSolicitud = prompt("Ingresa el ID de la solicitud aprobada:");
            if (idSolicitud) {
                document.getElementById("cita-id-solicitud").value = idSolicitud;
                showModal("modal-cita-visita");
            }
        }
    });

    console.log("Global Event Delegation activado.");

    console.log("Listeners de navegación adjuntados.");


    // Check session - Listener moved to delegation

    if (token) {
        try {
            const res = await apiCall("/auth/me");
            if (res && res.user) {
                currentUser = res.user;
                updateUIForUser();
                navigateBasedOnRole();
            }
        } catch (e) {
            console.warn("Error validando sesión:", e);
            logout();
        }
    } else {
        showScreen("welcome-screen");
    }

    // ========================================
    // AUTH
    // ========================================
    document.getElementById("login-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        const email = e.target["login-email"].value;
        const password = e.target["login-password"].value;

        try {
            const res = await apiCall("/auth/login", "POST", { email, password });
            token = res.token;
            currentUser = res.user;
            localStorage.setItem("paw_token", token);
            alert("¡Bienvenido!");
            updateUIForUser();
            navigateBasedOnRole();
            e.target.reset();
        } catch (err) {
            alert(err.message);
        }
    });

    document.getElementById("register-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        const name = e.target["register-name"].value;
        const email = e.target["register-email"].value;
        const phone = e.target["register-phone"].value;
        const password = e.target["register-password"].value;

        try {
            await apiCall("/auth/register-adoptante", "POST", {
                nombre: name,
                email,
                telefono: phone,
                password
            });
            alert("Registro exitoso. Por favor inicia sesión.");
            showScreen("login-screen");
            e.target.reset();
        } catch (err) {
            alert(err.message);
        }
    });

    // ========================================
    // ADOPTANTE SCREENS
    // ========================================
    async function renderAdoptanteScreen() {
        try {
            const perfData = await apiCall("/adoptante/perfil");
            currentUser.profileData = perfData.perfil;
            currentUser.profileComplete = !!perfData.perfil;
        } catch (e) {
            console.log("No perfil found or error");
        }

        // Filter listener handled by delegation

        if (!currentUser.profileComplete) {
            document.getElementById("profile-status").classList.remove("hidden");
            document.getElementById("profile-display").classList.add("hidden");

            // Button listener handled by delegation

        } else {
            document.getElementById("profile-status").classList.add("hidden");
            document.getElementById("profile-display").classList.remove("hidden");
            displayAdoptanteProfile();
        }

        renderPetsGrid();
        renderAdoptanteSolicitudes();
        window.showAdoptanteTab("perfil-adoptante");
    }

    async function renderPetsGrid(filters = {}) {
        const grid = document.getElementById("pets-grid");
        grid.innerHTML = "<p>Cargando mascotas...</p>";

        try {
            const res = await apiCall("/mascotas?available=true");
            let pets = res.mascotas || [];
            console.log("Mascotas raw:", pets);

            if (filters.species) {
                pets = pets.filter(p => {
                    const spId = p.especie_id;
                    const spName = spId === 1 ? 'perro' : (spId === 2 ? 'gato' : 'otro');
                    return spName === filters.species.toLowerCase();
                });
            }

            if (pets.length === 0) {
                console.log("No pets found after filtering. Filters:", filters);
                grid.innerHTML = `<div class="empty-state"><div class="empty-state-text">No se encontraron mascotas</div></div>`;
                return;
            }

            grid.innerHTML = pets.map(pet => {
                const especie = pet.especie_id === 1 ? 'perro' : 'gato';
                const img = pet.url_foto || `https://via.placeholder.com/400x220/e0f7ff/0077b6?text=${especie === 'perro' ? '🐕' : '🐈'}`;

                return `
                <div class="pet-card" onclick="viewPetDetails(${pet.id_mascota})">
                    <img src="${img}" class="pet-card-image">
                    <div class="pet-card-content">
                        <div class="pet-card-name">${pet.nombre}</div>
                        <div class="pet-card-info"><strong>Rescate:</strong> ${pet.situacion || '?'}</div>
                        <div class="pet-card-info"><strong>Nec. Esp:</strong> ${pet.necesidades_especiales ? 'Sí' : 'No'}</div>
                         <div class="pet-card-actions">
                            <button class="btn btn-small" onclick="event.stopPropagation(); viewPetDetails(${pet.id_mascota})">Ver Detalles</button>
                        </div>
                    </div>
                </div>`;
            }).join("");

        } catch (err) {
            console.error(err);
            grid.innerHTML = `<p class="error">Error cargando mascotas: ${err.message}</p>`;
        }
    }


    async function renderAdoptanteSolicitudes() {
        const list = document.getElementById("solicitudes-list");
        try {
            const res = await apiCall("/solicitudes/mis");
            if (!res.solicitudes || res.solicitudes.length === 0) {
                list.innerHTML = `<div class="empty-state">No tienes solicitudes enviadas.</div>`;
                return;
            }
            list.innerHTML = res.solicitudes.map(req => `
            <div class="request-card">
                <div class="request-header">
                     <span class="status-badge ${req.estado}">${req.estado}</span>
                </div>
                <div>📅 Fecha: ${req.fecha_solicitud}</div>
                <div>🆔 Mascota ID: ${req.id_mascota}</div>
                ${req.motivo_rechazo ? `<div class="alert alert-danger">Motivo rechazo: ${req.motivo_rechazo}</div>` : ''}
            </div>
          `).join("");
        } catch (e) {
            list.innerHTML = "<p>Error cargando solicitudes.</p>";
        }
    }

    window.viewPetDetails = async function (id) {
        try {
            const res = await apiCall(`/mascotas/${id}`);
            const pet = res.mascota;
            const content = document.getElementById("pet-details-content");
            const especie = pet.especie_id === 1 ? 'perro' : 'gato';
            const img = pet.url_foto || `https://via.placeholder.com/600x300/e0f7ff/0077b6?text=${especie === 'perro' ? '🐕' : '🐈'}`;

            // Listas
            const vacunasHtml = pet.vacunas?.map(v => `<li>${v.vacuna} (Aplicada: ${v.fecha_aplicacion})</li>`).join("") || "<li>Sin vacunas registradas</li>";
            const padecimientosHtml = pet.padecimientos?.map(p => `<li>${p.padecimiento} - Tratamiento: ${p.tratamiento}</li>`).join("") || "<li>Ninguno</li>";
            const historialHtml = pet.historial_medico?.map(h => `<li>${h.fecha}: <strong>${h.tipo}</strong> - ${h.detalle}</li>`).join("") || "<li>Sin historial</li>";

            content.innerHTML = `
            <img src="${img}" style="width:100%;height:300px;object-fit:cover;border-radius:12px;">
            <h2>${pet.nombre}</h2>
            <p><strong>Situación de rescate:</strong> ${pet.situacion || 'No especificada'} (${pet.alcaldia || '?'})</p>
            <p><strong>Necesidades especiales:</strong> ${pet.necesidades_especiales || 'Ninguna'}</p>
            <p>${pet.comportamiento || 'Sin descripción de comportamiento.'}</p>
            
            <div class="pet-details-grid">
               <div class="pet-detail-item"><label>Edad</label><span>${pet.edad}</span></div>
               <div class="pet-detail-item"><label>Tamaño</label><span>${pet.tamanio}</span></div>
               <div class="pet-detail-item"><label>Sexo</label><span>${pet.sexo}</span></div>
            </div>

            <div style="margin-top:15px; text-align:left;">
                <h4>🩺 Historial Médico</h4>
                <ul>${historialHtml}</ul>
                <h4>💉 Vacunas</h4>
                <ul>${vacunasHtml}</ul>
                <h4>💊 Padecimientos</h4>
                <ul>${padecimientosHtml}</ul>
            </div>

            ${currentUser && currentUser.rol === 'adoptante' ?
                    `<button class="btn mt-20" onclick="startAdoptionRequest(${pet.id_mascota})">Solicitar Adopción</button>` : ''}
          `;
            showModal("modal-pet-details");
        } catch (e) {
            console.error(e);
            alert("Error cargando detalle");
        }
    };

    window.startAdoptionRequest = function (id) {
        if (!currentUser.profileComplete) {
            alert("Completa tu perfil primero");
            hideAllModals();
            showAdoptanteTab("perfil-adoptante");
            return;
        }
        if (!confirm("¿Deseas enviar solicitud para esta mascota?")) return;

        apiCall("/solicitudes", "POST", { id_mascota: id })
            .then(() => {
                alert("Solicitud enviada");
                hideAllModals();
                renderAdoptanteSolicitudes();
            })
            .catch(e => alert(e.message));
    };


    // ========================================
    // FUNDACION SCREENS
    // ========================================
    async function renderFundacionScreen() {
        renderFundacionSolicitudes();
        renderFundacionDonaciones();
        renderFundacionPets();

        // Button listener handled by delegation

        window.showFundacionTab("solicitudes");
    }

    async function renderFundacionPets() {
        const grid = document.getElementById("fundacion-pets-list");
        try {
            const res = await apiCall("/mascotas?available=true"); // Temporary fix to show something
            let pets = res.mascotas || [];
            if (pets.length === 0) {
                grid.innerHTML = "No tienes mascotas registradas.";
            } else {
                grid.innerHTML = pets.map(pet => `
                <div class="pet-card">
                    <div class="pet-card-content">
                        <div class="pet-card-name">${pet.nombre}</div>
                        <div class="pet-card-info">ID: ${pet.id_mascota}</div>
                    </div>
                </div>`).join("");
            }
        } catch (e) {
            grid.innerHTML = "Error cargando mascotas.";
        }
    }

    async function renderFundacionSolicitudes() {
        const list = document.getElementById("fundacion-solicitudes-list");
        try {
            const res = await apiCall("/fundacion/solicitudes");
            if (!res.solicitudes.length) {
                list.innerHTML = "No hay solicitudes recibidas.";
                return;
            }
            list.innerHTML = res.solicitudes.map(req => `
            <div class="request-card">
               <div>Solicitud #${req.id_solicitud} - Mascota ${req.id_mascota}</div>
               <div>Estado: ${req.estado}</div>
               <div>Adoptante ID: ${req.id_adoptante}</div>
               ${req.estado === 'pendiente' ? `
                 <button class="btn btn-small" onclick="aprobar(${req.id_solicitud})">Aprobar</button>
                 <button class="btn btn-small btn-danger" onclick="rechazar(${req.id_solicitud})">Rechazar</button>
               ` : ''}
            </div>
          `).join("");
        } catch (e) {
            console.error(e);
        }
    }

    window.aprobar = async function (id) {
        try {
            await apiCall(`/fundacion/solicitudes/${id}/aprobar`, "POST");
            alert("Aprobada");
            renderFundacionSolicitudes();
        } catch (e) { alert(e.message); }
    }

    window.rechazar = async function (id) {
        const motivo = prompt("Motivo:");
        if (!motivo) return;
        try {
            await apiCall(`/fundacion/solicitudes/${id}/rechazar`, "POST", { motivo });
            alert("Rechazada");
            renderFundacionSolicitudes();
        } catch (e) { alert(e.message); }
    }

    async function renderFundacionDonaciones() {
        const list = document.getElementById("fundacion-donaciones-list");
        try {
            const res = await apiCall("/fundacion/donaciones");
            if (!res.donaciones.length) {
                list.innerHTML = "No hay donaciones.";
                return;
            }
            list.innerHTML = res.donaciones.map(d => `
               <div class="request-card">
                  <div>💰 $${d.monto}</div>
                  <div>De: ${d.donador_nombre || d.donador_email || 'Anónimo'}</div>
                  <div>Mensaje: ${d.mensaje || '-'}</div>
               </div>
             `).join("");
        } catch (e) { }
    }

    // ========================================
    // PERFIL & SEPOMEX
    // ========================================
    function displayAdoptanteProfile() {
        const p = currentUser.profileData;
        document.getElementById("profile-display").innerHTML = `
          <h3>Tu Perfil</h3>
          <p><strong>Nombre:</strong> ${p.nombre}</p>
          <p><strong>CP:</strong> ${p.codigo_postal || p.cp}</p>
          <button class="btn" onclick="editProfile()">Editar</button>
        `;
    }

    window.editProfile = function () {
        showModal("modal-profile");
    }

    document.getElementById("profile-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const data = Object.fromEntries(fd.entries());
        const cleanData = {};
        for (const [k, v] of Object.entries(data)) {
            const cleanKey = k.replace("profile-", "").replace(/-/g, "_");
            cleanData[cleanKey] = v;
        }
        try {
            await apiCall("/adoptante/perfil", "POST", { data: cleanData });
            alert("Perfil guardado");
            hideAllModals();
            renderAdoptanteScreen();
        } catch (e) {
            alert(e.message);
        }
    });

    const cpInput = document.getElementById("profile-cp");
    if (cpInput) {
        cpInput.addEventListener("change", async () => {
            const cp = cpInput.value;
            if (cp.length === 5) {
                try {
                    const res = await apiCall(`/sepomex/cp/${cp}`);
                    if (res.found) {
                        const sel = document.getElementById("profile-asentamiento");
                        sel.innerHTML = "";
                        res.items.forEach(i => {
                            const op = document.createElement("option");
                            op.value = i.asentamiento;
                            op.textContent = i.asentamiento;
                            sel.appendChild(op);
                        });
                        document.getElementById("profile-estado").value = res.estado;
                        document.getElementById("profile-municipio").value = res.municipio;
                    }
                } catch (e) { }
            }
        });
    }

    // ========================================
    // MISSING UI LOGIC 
    // ========================================
    // Cita Visita
    // Citas - Button handled by delegation

    document.getElementById("cita-form")?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const idSol = e.target["cita-id-solicitud"].value;
        const fechaHora = e.target["cita-fecha-hora"].value;
        const notas = e.target["cita-notas"].value;

        try {
            await apiCall("/citas", "POST", {
                id_solicitud: idSol,
                fecha_hora: fechaHora,
                notas
            });
            alert("Cita agendada con éxito");
            hideAllModals();
            // renderAdoptanteCitas(); // Si tuviéramos esa funcion implementada
        } catch (e) {
            alert(e.message);
        }
    });

    // Rescates
    // Rescates - Button handled by delegation

    document.getElementById("rescate-form")?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const idMascota = e.target["rescate-id-mascota"].value;
        const fecha = e.target["rescate2-fecha"].value;
        const alcaldia = e.target["rescate2-alcaldia"].value;
        const situacion = e.target["rescate2-situacion"].value;
        const necesidades = e.target["rescate2-necesidades"].value;
        const fuente = e.target["rescate-fuente"]?.value || "";

        try {
            await apiCall("/rescates", "POST", {
                id_mascota: idMascota,
                fecha,
                alcaldia,
                situacion,
                necesidades,
                fuente
            });
            alert("Rescate registrado exitosamente");
            hideAllModals();
        } catch (e) {
            alert(e.message);
        }
    });

    // Lista Negra
    // Lista Negra
    // Lista Negra - Button handled by delegation

    document.getElementById("lista-negra-form")?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const nombre = e.target["ln-duenio-nombre"].value;
        const tipo = e.target["ln-tipo"].value; // temporal/definitiva
        const fecha = e.target["ln-fecha"].value;
        const motivo = e.target["ln-motivo"].value;

        try {
            await apiCall("/lista-negra", "POST", {
                nombre_duenio: nombre,
                motivo: motivo,
                fecha_inicio: fecha,
                tipo: tipo
            });
            alert("Agregado a lista negra");
            hideAllModals();
            // renderFundacionListaNegra();
        } catch (e) {
            alert(e.message);
        }
    });

    // Agregar Mascota
    // Agregar Mascota - Button handled by delegation
    document.getElementById("pet-form")?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const body = {
            nombre: fd.get("pet-name"),
            especie: fd.get("pet-species"),
            raza: fd.get("pet-breed"),
            edad_anios: parseInt(fd.get("pet-age-years") || 0),
            edad_meses: parseInt(fd.get("pet-age-months") || 0),
            sexo: fd.get("pet-gender"),
            tamanio: fd.get("pet-size"),
            nivel_energia: fd.get("pet-energy"),
            comportamiento: fd.get("pet-behavior"),
            estado_salud: fd.get("pet-health"),
            cp: fd.get("pet-cp"),
            vacunado: fd.get("pet-vaccinated") === "on",
            esterilizado: fd.get("pet-sterilized") === "on",
            senias_particulares: fd.get("pet-special"),
            url_foto: fd.get("pet-image"),

            rescate_fecha: fd.get("rescate-fecha"),
            rescate_alcaldia: fd.get("rescate-alcaldia"),
            rescate_situacion: fd.get("rescate-situacion"),
            rescate_necesidades: fd.get("rescate-necesidades"),
            rescate_fuente: fd.get("rescate-fuente")
        };

        try {
            await apiCall("/mascotas", "POST", body);
            alert("Mascota y rescate registrados exitosamente");
            hideAllModals();
            e.target.reset();
            if (window.renderFundacionPets) window.renderFundacionPets();
        } catch (err) {
            alert("Error al registrar: " + err.message);
        }
    });


    // ========================================
    // UTILS & TABS
    // ========================================
    // ========================================
    // UTILS & TABS
    // ========================================

    // Top Nav Buttons - Home handled by delegation

    document.getElementById("nav-donate")?.addEventListener("click", (e) => {
        e.preventDefault();
        // If user is logged in as adoptante, show donor screen? Or just generic donate modal?
        // Assuming user wants to go to donor screen if adoptante, or just show list of foundations
        if (currentUser && currentUser.rol === 'fundacion') {
            alert("Eres una fundación. No puedes donarte a ti mismo (aún).");
        } else {
            showScreen("donador-screen");
        }
    });

    document.getElementById("nav-notifications")?.addEventListener("click", (e) => {
        e.preventDefault();
        const badge = document.getElementById("notification-badge");
        if (badge) badge.classList.add("hidden");
        showModal("modal-notifications");
        // Here we would fetch notifications if API existed
        document.getElementById("notifications-list").innerHTML = "<p>No tienes nuevas notificaciones</p>";
    });
    // END FIX: Top Nav Buttons


    window.showAdoptanteTab = function (tab) {
        document.querySelectorAll(".adoptante-tab-content").forEach(t => t.classList.add("hidden"));
        document.querySelectorAll(".tab-link-adoptante").forEach(t => t.classList.remove("active"));
        document.querySelector(`.tab-link-adoptante[data-tab="${tab}"]`)?.classList.add("active");
        document.getElementById(`adoptante-${tab}`)?.classList.remove("hidden");
    };
    window.showFundacionTab = function (tab) {
        document.querySelectorAll(".fundacion-tab-content").forEach(t => t.classList.add("hidden"));
        document.querySelectorAll(".tab-link-fundacion").forEach(t => t.classList.remove("active"));
        document.querySelector(`.tab-link-fundacion[data-tab="${tab}"]`)?.classList.add("active");
        document.getElementById(`fundacion-${tab}`)?.classList.remove("hidden");
    };

    // Tab event listeners
    document.querySelectorAll('.tab-link-adoptante').forEach(link => {
        link.addEventListener('click', () => window.showAdoptanteTab(link.dataset.tab));
    });
    document.querySelectorAll('.tab-link-fundacion').forEach(link => {
        link.addEventListener('click', () => window.showFundacionTab(link.dataset.tab));
    });

    // Employee Modal Logic
    const empPuestoSel = document.getElementById("emp-puesto");
    if (empPuestoSel) {
        empPuestoSel.addEventListener("change", () => {
            const extras = document.getElementById("emp-extra-fields");
            if (empPuestoSel.value === "Cuidador") {
                extras.classList.remove("hidden");
            } else {
                extras.classList.add("hidden");
            }
        });
    }

    document.getElementById("empleado-form")?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const nombre = document.getElementById("emp-nombre").value;
        const puesto = document.getElementById("emp-puesto").value;
        let area = null, turno = null;

        if (puesto === "Cuidador") {
            area = document.getElementById("emp-area").value;
            turno = document.getElementById("emp-turno").value;
        }

        try {
            await apiCall("/fundacion/empleados", "POST", { nombre, puesto, area, turno });
            alert("Colaborador registrado exitosamente");
            hideAllModals();
            e.target.reset();
            if (window.renderEmpleados) window.renderEmpleados();
        } catch (err) {
            alert(err.message);
        }
    });

    document.querySelectorAll("[data-close]").forEach(b => b.onclick = hideAllModals);

});