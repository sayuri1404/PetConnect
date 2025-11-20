// ========================================
// PARTE 1: VARIABLES GLOBALES, DATOS INICIALES Y UTILIDADES
// ========================================

document.addEventListener('DOMContentLoaded', () => {
    // ========================================
    // VARIABLES GLOBALES Y ESTADO
    // ========================================
    let dataCodigos = {}; // Datos del CSV de códigos postales
    let currentUser = null; // Usuario actualmente logueado
    let users = []; // Base de datos de usuarios
    let pets = []; // Base de datos de mascotas
    let adoptionRequests = []; // Solicitudes de adopción
    let donations = []; // Donaciones
    let notifications = []; // Notificaciones

    // IDs para generación
    let nextUserId = 1;
    let nextPetId = 1;
    let nextRequestId = 1;
    let nextDonationId = 1;
    let nextNotificationId = 1;

    // ========================================
    // DATOS INICIALES - 20 MASCOTAS
    // ========================================
    function initializePets() {
        const petsData = [
            // PERROS (10)
            {
                id: nextPetId++,
                name: "Max",
                species: "perro",
                breed: "Labrador Retriever",
                age: { years: 2, months: 6 },
                gender: "macho",
                size: "grande",
                behavior: "Muy juguetón y amigable. Le encanta nadar y jugar a la pelota. Excelente con niños y otras mascotas.",
                health: "Saludable, todas las vacunas al día",
                vaccinated: true,
                sterilized: true,
                special: "Tiene una mancha blanca en el pecho en forma de corazón",
                image: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "06700",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Luna",
                species: "perro",
                breed: "Golden Retriever",
                age: { years: 1, months: 3 },
                gender: "hembra",
                size: "grande",
                behavior: "Dulce y cariñosa. Ama los abrazos y estar cerca de las personas. Perfecta para familias.",
                health: "Excelente estado de salud",
                vaccinated: true,
                sterilized: false,
                special: "Pelaje dorado brillante, muy fotogénica",
                image: "https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "03100",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Rocky",
                species: "perro",
                breed: "Bulldog Francés",
                age: { years: 3, months: 0 },
                gender: "macho",
                size: "pequeño",
                behavior: "Tranquilo y relajado. Le gusta dormir y ver televisión. Ideal para departamentos.",
                health: "Saludable, requiere cuidado especial en climas cálidos",
                vaccinated: true,
                sterilized: true,
                special: "Orejas grandes y expresivas, ronca al dormir",
                image: "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "11000",
                available: true,
                energy: "bajo"
            },
            {
                id: nextPetId++,
                name: "Bella",
                species: "perro",
                breed: "Beagle",
                age: { years: 4, months: 2 },
                gender: "hembra",
                size: "mediano",
                behavior: "Activa y curiosa. Le encanta explorar y seguir rastros. Muy vocal y comunicativa.",
                health: "Saludable, vacunas completas",
                vaccinated: true,
                sterilized: true,
                special: "Orejas largas y cola blanca en la punta",
                image: "https://images.unsplash.com/photo-1505628346881-b72b27e84530?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "01000",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Toby",
                species: "perro",
                breed: "Schnauzer Miniatura",
                age: { years: 5, months: 8 },
                gender: "macho",
                size: "pequeño",
                behavior: "Inteligente y protector. Excelente guardián. Leal y cariñoso con su familia.",
                health: "Saludable, todas las vacunas al día",
                vaccinated: true,
                sterilized: true,
                special: "Barba característica y cejas prominentes",
                image: "https://images.unsplash.com/photo-1568572933382-74d440642117?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "14000",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Coco",
                species: "perro",
                breed: "Chihuahua",
                age: { years: 2, months: 0 },
                gender: "hembra",
                size: "pequeño",
                behavior: "Pequeña pero valiente. Muy cariñosa con su dueño. Le gusta estar en brazos.",
                health: "Saludable, vacunas al día",
                vaccinated: true,
                sterilized: false,
                special: "Ojos grandes y expresivos, color café claro",
                image: "https://images.unsplash.com/photo-1612536284355-cac07f3e4228?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "06700",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Bruno",
                species: "perro",
                breed: "Boxer",
                age: { years: 3, months: 6 },
                gender: "macho",
                size: "grande",
                behavior: "Energético y juguetón. Excelente con niños. Necesita mucho ejercicio diario.",
                health: "Saludable, todas las vacunas",
                vaccinated: true,
                sterilized: true,
                special: "Manchas negras en el hocico, muy expresivo",
                image: "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "09000",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Lola",
                species: "perro",
                breed: "Cocker Spaniel",
                age: { years: 6, months: 0 },
                gender: "hembra",
                size: "mediano",
                behavior: "Tranquila y gentil. Le encanta que la peinen. Perfecta para adultos mayores.",
                health: "Saludable, requiere limpieza regular de oídos",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje largo y sedoso, orejas caídas",
                image: "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "11000",
                available: true,
                energy: "bajo"
            },
            {
                id: nextPetId++,
                name: "Zeus",
                species: "perro",
                breed: "Pastor Alemán",
                age: { years: 4, months: 0 },
                gender: "macho",
                size: "grande",
                behavior: "Inteligente y obediente. Excelente para entrenamiento. Protector de su familia.",
                health: "Saludable, todas las vacunas al día",
                vaccinated: true,
                sterilized: true,
                special: "Orejas erguidas, mirada alerta",
                image: "https://images.unsplash.com/photo-1568393691622-c7ba131d63b4?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "01000",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Mia",
                species: "perro",
                breed: "Mestizo",
                age: { years: 1, months: 0 },
                gender: "hembra",
                size: "mediano",
                behavior: "Alegre y adaptable. Se lleva bien con todos. Perfecta para familias activas.",
                health: "Saludable, vacunas completas",
                vaccinated: true,
                sterilized: false,
                special: "Mezcla única de colores, cola rizada",
                image: "https://images.unsplash.com/photo-1477884213360-7e9d7dcc1e48?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "03100",
                available: true,
                energy: "medio"
            },

            // GATOS (10)
            {
                id: nextPetId++,
                name: "Simba",
                species: "gato",
                breed: "Naranja Atigrado",
                age: { years: 2, months: 0 },
                gender: "macho",
                size: "mediano",
                behavior: "Sociable y juguetón. Le encanta trepar y perseguir juguetes. Ronronea mucho.",
                health: "Saludable, todas las vacunas al día",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje naranja intenso con rayas, bigotes largos",
                image: "https://images.unsplash.com/photo-1574158622682-e40e69881006?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "06700",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Nala",
                species: "gato",
                breed: "Siamés",
                age: { years: 1, months: 6 },
                gender: "hembra",
                size: "pequeño",
                behavior: "Vocal y comunicativa. Muy inteligente. Le gusta estar cerca de su dueño.",
                health: "Excelente salud",
                vaccinated: true,
                sterilized: false,
                special: "Ojos azules brillantes, pelaje color crema con extremidades oscuras",
                image: "https://images.unsplash.com/photo-1513245543132-31f507417b26?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "11000",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Pelusa",
                species: "gato",
                breed: "Persa",
                age: { years: 3, months: 0 },
                gender: "hembra",
                size: "mediano",
                behavior: "Tranquila y elegante. Le gusta dormir en lugares suaves. Requiere cepillado diario.",
                health: "Saludable, requiere limpieza regular de ojos",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje largo y esponjoso, cara achatada",
                image: "https://images.unsplash.com/photo-1595433707802-6b2626ef1c91?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "03100",
                available: true,
                energy: "bajo"
            },
            {
                id: nextPetId++,
                name: "Félix",
                species: "gato",
                breed: "Blanco y Negro",
                age: { years: 4, months: 0 },
                gender: "macho",
                size: "mediano",
                behavior: "Independiente pero cariñoso. Cazador nato. Le gusta observar por la ventana.",
                health: "Saludable, vacunas completas",
                vaccinated: true,
                sterilized: true,
                special: "Patrón de esmoquin, bigote negro en un lado",
                image: "https://images.unsplash.com/photo-1529257414772-1960b7bea4eb?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "01000",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Michi",
                species: "gato",
                breed: "Mestizo",
                age: { years: 5, months: 0 },
                gender: "macho",
                size: "mediano",
                behavior: "Relajado y amistoso. Se adapta fácilmente. Bueno con niños respetuosos.",
                health: "Saludable, todas las vacunas",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje gris atigrado, patas blancas",
                image: "https://images.unsplash.com/photo-1573865526739-10c1d3a1e83e?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "14000",
                available: true,
                energy: "bajo"
            },
            {
                id: nextPetId++,
                name: "Luna",
                species: "gato",
                breed: "Negro",
                age: { years: 2, months: 6 },
                gender: "hembra",
                size: "pequeño",
                behavior: "Juguetona y curiosa. Le encanta explorar. Muy activa por las noches.",
                health: "Saludable, vacunas al día",
                vaccinated: true,
                sterilized: false,
                special: "Pelaje negro brillante, ojos verdes intensos",
                image: "https://images.unsplash.com/photo-1597843786411-48eee8e5c4e6?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "06700",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Garfield",
                species: "gato",
                breed: "Naranja Tabby",
                age: { years: 6, months: 0 },
                gender: "macho",
                size: "grande",
                behavior: "Tranquilo y glotón. Le encanta comer y dormir. Muy cariñoso a su manera.",
                health: "Saludable, necesita dieta controlada",
                vaccinated: true,
                sterilized: true,
                special: "Robusto, pelaje naranja con rayas",
                image: "https://images.unsplash.com/photo-1574158622682-e40e69881006?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "09000",
                available: true,
                energy: "bajo"
            },
            {
                id: nextPetId++,
                name: "Kitty",
                species: "gato",
                breed: "Calicó",
                age: { years: 1, months: 3 },
                gender: "hembra",
                size: "pequeño",
                behavior: "Dulce y tímida al principio. Muy cariñosa cuando toma confianza. Le gustan los lugares altos.",
                health: "Saludable, vacunas completas",
                vaccinated: true,
                sterilized: false,
                special: "Pelaje tricolor (naranja, negro y blanco), única en su tipo",
                image: "https://images.unsplash.com/photo-1606214174585-fe31582dc6ee?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "11000",
                available: true,
                energy: "medio"
            },
            {
                id: nextPetId++,
                name: "Tom",
                species: "gato",
                breed: "Gris Azulado",
                age: { years: 3, months: 6 },
                gender: "macho",
                size: "mediano",
                behavior: "Juguetón y atlético. Le encanta saltar y trepar. Muy entretenido de observar.",
                health: "Saludable, todas las vacunas",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje gris azulado, ojos amarillos",
                image: "https://images.unsplash.com/photo-1570458436416-b8fcccfe883e?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "03100",
                available: true,
                energy: "alto"
            },
            {
                id: nextPetId++,
                name: "Minina",
                species: "gato",
                breed: "Mestizo",
                age: { years: 7, months: 0 },
                gender: "hembra",
                size: "mediano",
                behavior: "Madura y cariñosa. Perfecta para hogares tranquilos. Le encanta recibir caricias.",
                health: "Saludable para su edad, vacunas al día",
                vaccinated: true,
                sterilized: true,
                special: "Pelaje atigrado marrón, muy expresiva",
                image: "https://images.unsplash.com/photo-1472491235688-bdc81a63246e?w=400",
                fundacion: "Fundación Patitas Felices",
                fundacionId: null,
                cp: "01000",
                available: true,
                energy: "bajo"
            }
        ];

        pets = petsData;
    }

    // ========================================
    // CARGAR DATOS DE CÓDIGOS POSTALES
    // ========================================
    function cargarDatosCodigosPostales() {
        // Asegúrate de que este archivo CSV esté en la misma carpeta que tu HTML
        fetch('codigos_postales_merged(1).csv')
            .then(response => {
                if (!response.ok) throw new Error("Error al cargar CSV de Códigos Postales");
                return response.text();
            })
            .then(csvText => {
                Papa.parse(csvText, {
                    header: true,
                    skipEmptyLines: true,
                    complete: (results) => {
                        dataCodigos = results.data.reduce((acc, row) => {
                            const cp = row.codigo_postal;
                            if (cp) {
                                if (!acc[cp]) acc[cp] = [];
                                acc[cp].push({
                                    asentamiento: row.asentamiento,
                                    tipo_asentamiento: row.tipo_asentamiento,
                                    municipio: row.municipio,
                                    estado: row.estado,
                                    ciudad: row.ciudad,
                                    clave_oficina: row.clave_oficina
                                });
                            }
                            return acc;
                        }, {});
                        console.log("✅ Datos de códigos postales cargados");
                    }
                });
            })
            .catch(error => console.error('Error al cargar CSV:', error));
    }

    // ========================================
    // FUNCIONES DE NAVEGACIÓN
    // ========================================
    function showScreen(screenId) {
        document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
        document.getElementById(screenId)?.classList.remove('hidden');
    }

    function showModal(modalId) {
        document.getElementById('modal-overlay').classList.remove('hidden');
        document.getElementById(modalId)?.classList.remove('hidden');
    }

    function hideAllModals() {
        document.getElementById('modal-overlay').classList.add('hidden');
        document.querySelectorAll('.modal').forEach(m => m.classList.add('hidden'));
    }

    // ========================================
    // PARTE 2/5: AUTENTICACIÓN Y NOTIFICACIONES
    // ========================================

    // ========================================
    // SISTEMA DE AUTENTICACIÓN
    // ========================================
    function login(email, password) {
        const user = users.find(u => u.email === email && u.password === password);
        if (user) {
            currentUser = user;
            updateUIForUser();
            showScreen(getScreenForUserType(user.type));
            
            if (user.type === 'adoptante') renderAdoptanteScreen();
            else if (user.type === 'fundacion') renderFundacionScreen();
            else if (user.type === 'donador') renderDonadorScreen();
            
            return true;
        }
        return false;
    }

    function register(userData) {
        const existingUser = users.find(u => u.email === userData.email);
        if (existingUser) {
            alert('Este correo ya está registrado');
            return false;
        }

        const newUser = {
            id: nextUserId++,
            ...userData,
            profileComplete: false,
            profileData: null,
            createdAt: new Date()
        };

        users.push(newUser);
        currentUser = newUser;
        updateUIForUser();
        showScreen(getScreenForUserType(newUser.type));
        
        if (newUser.type === 'fundacion') {
            // Asigna todas las mascotas iniciales a la primera fundación que se registre
            assignPetsToFundacion(newUser.id);
        }
        
        if (newUser.type === 'adoptante') renderAdoptanteScreen();
        else if (newUser.type === 'fundacion') renderFundacionScreen();
        else if (newUser.type === 'donador') renderDonadorScreen();
        
        return true;
    }

    function assignPetsToFundacion(fundacionId) {
        const fundacion = users.find(u => u.id === fundacionId);
        if (!fundacion) return;
        
        pets.forEach(pet => {
            if (!pet.fundacionId) { // Solo asigna mascotas que no tengan ya una fundación
                pet.fundacion = fundacion.fundacionName || fundacion.name;
                pet.fundacionId = fundacionId;
            }
        });
    }

    function logout() {
        currentUser = null;
        document.getElementById('nav-logged-in').classList.add('hidden');
        document.getElementById('nav-logged-out').classList.remove('hidden');
        showScreen('welcome-screen');
    }

    function updateUIForUser() {
        if (currentUser) {
            document.getElementById('nav-logged-out').classList.add('hidden');
            document.getElementById('nav-logged-in').classList.remove('hidden');
            document.getElementById('welcome-message').textContent = `Hola, ${currentUser.name}`;
            updateNotificationBadge();
        }
    }

    function getScreenForUserType(type) {
        const screens = {
            'adoptante': 'adoptante-screen',
            'fundacion': 'fundacion-screen',
            'donador': 'donador-screen'
        };
        return screens[type] || 'welcome-screen';
    }

    // ========================================
    // SISTEMA DE NOTIFICACIONES
    // ========================================
    function addNotification(userId, type, title, message) {
        const notification = {
            id: nextNotificationId++,
            userId: userId,
            type: type, // 'info', 'success', 'error'
            title: title,
            message: message,
            read: false,
            createdAt: new Date()
        };
        notifications.push(notification);
        
        // Actualiza el badge solo si la notificación es para el usuario actual
        if (currentUser && currentUser.id === userId) {
            updateNotificationBadge();
        }
    }

    function updateNotificationBadge() {
        if (!currentUser) return;
        const unreadCount = notifications.filter(n => n.userId === currentUser.id && !n.read).length;
        const badge = document.getElementById('notification-badge');
        if (unreadCount > 0) {
            badge.textContent = unreadCount;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    }

    function showNotifications() {
        if (!currentUser) return;
        
        const userNotifications = notifications.filter(n => n.userId === currentUser.id).reverse();
        const notificationsList = document.getElementById('notifications-list');
        
        if (userNotifications.length === 0) {
            notificationsList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">🔔</div>
                    <div class="empty-state-text">No tienes notificaciones</div>
                </div>
            `;
        } else {
            notificationsList.innerHTML = userNotifications.map(n => `
                <div class="notification-item ${n.type}">
                    <div class="notification-header">
                        <span class="notification-title">${n.title}</span>
                        <span class="notification-time">${formatDate(n.createdAt)}</span>
                    </div>
                    <div class="notification-message">${n.message}</div>
                </div>
            `).join('');
            
            // Marcar todas como leídas al abrirlas
            userNotifications.forEach(n => n.read = true);
            updateNotificationBadge();
        }
        
        showModal('modal-notifications');
    }

    // ========================================
    // FUNCIONES DE UTILIDAD
    // ========================================
    function formatDate(date) {
        const now = new Date();
        const diff = now - new Date(date);
        const minutes = Math.floor(diff / 60000);
        const hours = Math.floor(diff / 3600000);
        const days = Math.floor(diff / 86400000);
        
        if (minutes < 1) return `Hace segundos`;
        if (minutes < 60) return `Hace ${minutes} min`;
        if (hours < 24) return `Hace ${hours} h`;
        return `Hace ${days} días`;
    }

    function getAgeCategory(years) {
        if (years < 1) return 'cachorro';
        if (years < 3) return 'joven';
        if (years < 7) return 'adulto';
        return 'senior';
    }

function calculateCompatibility(pet, userProfile) {
    let score = 0;
    const reasons = [];

    // --------------------------
    // Energía vs tiempo disponible
    // --------------------------
    if (userProfile.tiempo_dedicado === 'mas-2h' && pet.energy === 'alto') {
        score += 30;
        reasons.push('Tienes tiempo para una mascota muy activa');
    } else if (userProfile.tiempo_dedicado === '1-2h' && (pet.energy === 'medio' || pet.energy === 'bajo')) {
        score += 20;
        reasons.push('Tu tiempo disponible encaja con una mascota de energía media');
    } else if (userProfile.tiempo_dedicado === 'menos-1h' && pet.energy === 'bajo') {
        score += 15;
        reasons.push('Mascota tranquila para poco tiempo disponible');
    }

    // --------------------------
    // Horas fuera de casa
    // --------------------------
    if (userProfile.horas_fuera === 'menos-4' && pet.energy === 'bajo') {
        score += 20;
        reasons.push('Mascota tranquila y poco tiempo fuera de casa');
    } else if (userProfile.horas_fuera === '4-8' && (pet.energy === 'medio' || pet.energy === 'alto')) {
        score += 15;
        reasons.push('Tu rutina es compatible con una mascota activa');
    }

    // --------------------------
    // Tipo de vivienda vs tamaño
    // --------------------------
    if (userProfile.tipo_vivienda === 'casa-jardin' && (pet.size === 'grande' || pet.size === 'mediano')) {
        score += 25;
        reasons.push('Cuentas con espacio adecuado para su tamaño');
    } else if (
        (userProfile.tipo_vivienda === 'departamento-pequeno' || userProfile.tipo_vivienda === 'departamento-amplio')
        && pet.size === 'pequeño'
    ) {
        score += 25;
        reasons.push('Ideal para departamento');
    } else if (userProfile.tipo_vivienda === 'casa-sin-jardin' && (pet.size === 'pequeño' || pet.size === 'mediano')) {
        score += 15;
        reasons.push('El tamaño de la mascota es adecuado para tu hogar');
    }

    // --------------------------
    // Experiencia
    // --------------------------
    if (userProfile.experiencia_previa === 'si') {
        score += 15;
        reasons.push('Tu experiencia previa es una ventaja');
    } else {
        score += 5; // No tener experiencia no es malo, solo menos ventaja
    }

    // --------------------------
    // Niños en casa
    // --------------------------
    const hayNinos = Array.isArray(userProfile.ninos_rango) &&
                     userProfile.ninos_rango.length > 0 &&
                     !userProfile.ninos_rango.includes('no-hay');

    if (hayNinos && pet.behavior.toLowerCase().includes('niños')) {
        score += 20;
        reasons.push('Compatible con hogares con niñas y niños');
    }

    // --------------------------
    // Otras mascotas
    // --------------------------
    const tieneMascotas = Array.isArray(userProfile.otras_mascotas) &&
                          userProfile.otras_mascotas.length > 0 &&
                          !userProfile.otras_mascotas.includes('ninguna');

    if (tieneMascotas && pet.behavior.toLowerCase().includes('otras mascotas')) {
        score += 15;
        reasons.push('Se lleva bien con otras mascotas');
    }

    return {
        score: Math.min(score, 100),
        reasons: reasons.length > 0 ? reasons : ['Buena compatibilidad general']
    };
}


    function getStatusText(status) {
        const texts = {
            'pendiente': 'Pendiente',
            'aprobada': 'Aprobada',
            'rechazada': 'Rechazada',
            'completada': 'Completada'
        };
        return texts[status] || status;
    }

    // ========================================
    // PARTE 3/5: PANTALLA ADOPTANTE
    // ========================================

    // ========================================
    // PANTALLA ADOPTANTE
    // ========================================
    function renderAdoptanteScreen() {
        if (!currentUser || currentUser.type !== 'adoptante') return;

        if (!currentUser.profileComplete) {
            document.getElementById('profile-status').classList.remove('hidden');
            document.getElementById('profile-display').classList.add('hidden');
        } else {
            document.getElementById('profile-status').classList.add('hidden');
            document.getElementById('profile-display').classList.remove('hidden');
            displayAdoptanteProfile();
        }

        const userRequests = adoptionRequests.filter(r => r.adoptanteId === currentUser.id);
        document.getElementById('solicitudes-count').textContent = userRequests.length;

        renderPetsGrid();
        renderAdoptanteSolicitudes();
        
        // Asegurar que la pestaña correcta esté visible al cargar
        showAdoptanteTab('perfil-adoptante');
    }

function displayAdoptanteProfile() {
    const profile = currentUser.profileData;
    if (!profile) return;

    const profileDisplay = document.getElementById('profile-display');

    const ninosTexto = (Array.isArray(profile.ninos_rango) && profile.ninos_rango.length > 0)
        ? profile.ninos_rango.join(', ')
        : 'No especificado';

    const otrasMascotasTexto = (Array.isArray(profile.otras_mascotas) && profile.otras_mascotas.length > 0)
        ? profile.otras_mascotas.join(', ') + (profile.otras_mascotas_detalle ? ` (${profile.otras_mascotas_detalle})` : '')
        : 'No especificado';

    profileDisplay.innerHTML = `
        <div class="profile-section">
            <h3>👤 Información Personal</h3>
            <div class="profile-item"><span class="profile-label">Nombre:</span><span class="profile-value">${profile.nombre}</span></div>
            <div class="profile-item"><span class="profile-label">Edad:</span><span class="profile-value">${profile.edad} años</span></div>
            <div class="profile-item"><span class="profile-label">Teléfono móvil:</span><span class="profile-value">${profile.tel_movil}</span></div>
            ${profile.tel_fijo ? `<div class="profile-item"><span class="profile-label">Teléfono fijo:</span><span class="profile-value">${profile.tel_fijo}</span></div>` : ''}
            <div class="profile-item"><span class="profile-label">Correo:</span><span class="profile-value">${profile.email}</span></div>
        </div>

        <div class="profile-section">
            <h3>📍 Dirección</h3>
            <div class="profile-item"><span class="profile-label">Código Postal:</span><span class="profile-value">${profile.cp}</span></div>
            <div class="profile-item"><span class="profile-label">Estado:</span><span class="profile-value">${profile.estado}</span></div>
            <div class="profile-item"><span class="profile-label">Municipio:</span><span class="profile-value">${profile.municipio}</span></div>
            <div class="profile-item"><span class="profile-label">Colonia:</span><span class="profile-value">${profile.asentamiento}</span></div>
            <div class="profile-item"><span class="profile-label">Calle:</span><span class="profile-value">${profile.calle} ${profile.num_ext}${profile.num_int ? ' Int. ' + profile.num_int : ''}</span></div>
        </div>

        <div class="profile-section">
            <h3>🏠 Hogar y Vivienda</h3>
            <div class="profile-item"><span class="profile-label">Tipo de vivienda:</span><span class="profile-value">${profile.tipo_vivienda}</span></div>
            <div class="profile-item"><span class="profile-label">Situación de vivienda:</span><span class="profile-value">${profile.situacion_vivienda}</span></div>
            <div class="profile-item"><span class="profile-label">Espacio cercado:</span><span class="profile-value">${profile.espacio_cercado}</span></div>
            <div class="profile-item"><span class="profile-label">Adultos en el hogar:</span><span class="profile-value">${profile.adultos_hogar}</span></div>
            <div class="profile-item"><span class="profile-label">Personas en el hogar:</span><span class="profile-value">${profile.personas_hogar}</span></div>
            <div class="profile-item"><span class="profile-label">Niños en el hogar:</span><span class="profile-value">${ninosTexto}</span></div>
            <div class="profile-item"><span class="profile-label">Otras mascotas:</span><span class="profile-value">${otrasMascotasTexto}</span></div>
        </div>

        <div class="profile-section">
            <h3>🐾 Estilo de Vida y Compromiso</h3>
            <div class="profile-item"><span class="profile-label">Experiencia con mascotas:</span><span class="profile-value">${profile.experiencia_previa === 'si' ? 'Sí' : 'No'} (${profile.nivel_experiencia})</span></div>
            <div class="profile-item"><span class="profile-label">Horas fuera de casa:</span><span class="profile-value">${profile.horas_fuera}</span></div>
            <div class="profile-item"><span class="profile-label">Nivel de actividad buscado:</span><span class="profile-value">${profile.nivel_actividad}</span></div>
            <div class="profile-item"><span class="profile-label">Tiempo diario disponible:</span><span class="profile-value">${profile.tiempo_dedicado}</span></div>
            <div class="profile-item"><span class="profile-label">Acepta gastos veterinarios:</span><span class="profile-value">${profile.gastos_vet === 'si' ? 'Sí' : 'No'}</span></div>
            <div class="profile-item"><span class="profile-label">Compromiso de esterilización:</span><span class="profile-value">${profile.compromiso_esterilizacion === 'si' ? 'Sí' : 'No'}</span></div>
            <div class="profile-item"><span class="profile-label">Motivo de adopción:</span><span class="profile-value">${profile.motivo_adopcion}</span></div>
            <div class="profile-item"><span class="profile-label">Si tus circunstancias cambian:</span><span class="profile-value">${profile.que_haria_cambios}</span></div>
        </div>

        <div class="profile-section">
            <h3>🩺 Referencia Veterinaria</h3>
            <div class="profile-item"><span class="profile-label">Veterinario:</span><span class="profile-value">${profile.veterinario || 'No especificado'}</span></div>
        </div>

        <button class="btn btn-secondary mt-20" onclick="editProfile()" style="width: auto;">Editar Perfil</button>
    `;
}

    function renderPetsGrid(filters = {}) {
        const grid = document.getElementById('pets-grid');
        
        let filteredPets = pets.filter(p => p.available);

        if (filters.species) {
            filteredPets = filteredPets.filter(p => p.species === filters.species);
        }
        if (filters.age) {
            filteredPets = filteredPets.filter(p => getAgeCategory(p.age.years) === filters.age);
        }
        if (filters.size) {
            filteredPets = filteredPets.filter(p => p.size === filters.size);
        }

        // Aplicar compatibilidad si el checkbox está marcado y el perfil está completo
        if (filters.compatibility && currentUser?.profileComplete) {
            filteredPets = filteredPets.map(pet => {
                const compat = calculateCompatibility(pet, currentUser.profileData);
                return { ...pet, compatibility: compat };
            }).sort((a, b) => b.compatibility.score - a.compatibility.score);
        } else {
            // Limpiar compatibilidad si no se está filtrando
            filteredPets = filteredPets.map(pet => ({ ...pet, compatibility: null }));
        }

        if (filteredPets.length === 0) {
            grid.innerHTML = `
                <div class="empty-state" style="grid-column: 1 / -1;">
                    <div class="empty-state-icon">🐾</div>
                    <div class="empty-state-text">No se encontraron mascotas con estos filtros</div>
                </div>
            `;
            return;
        }

        grid.innerHTML = filteredPets.map(pet => `
            <div class="pet-card" onclick="viewPetDetails(${pet.id})">
                <img src="${pet.image}" alt="${pet.name}" class="pet-card-image" onerror="this.src='https://via.placeholder.com/400x220/e0f7ff/0077b6?text=${pet.species === 'perro' ? '🐕' : '🐈'}'">
                ${pet.compatibility ? `<div class="pet-card-badge" style="background-color: var(--accent-color);">${pet.compatibility.score}% Compatible</div>` : ''}
                <div class="pet-card-content">
                    <div class="pet-card-name">${pet.name}</div>
                    <div class="pet-card-info"><strong>Raza:</strong> ${pet.breed}</div>
                    <div class="pet-card-info"><strong>Edad:</strong> ${pet.age.years} año${pet.age.years !== 1 ? 's' : ''} ${pet.age.months > 0 ? pet.age.months + ' meses' : ''}</div>
                    <div class="pet-card-info"><strong>Tamaño:</strong> ${pet.size}</div>
                    <div class="pet-card-info"><strong>Fundación:</strong> ${pet.fundacion}</div>
                    <div class="pet-card-actions">
                        <button class="btn btn-small" onclick="event.stopPropagation(); viewPetDetails(${pet.id})">Ver Detalles</button>
                    </div>
                </div>
            </div>
        `).join('');
    }

    function viewPetDetails(petId) {
        const pet = pets.find(p => p.id === petId);
        if (!pet) return;

        const content = document.getElementById('pet-details-content');
        
        let compatibilityHTML = '';
        if (currentUser?.profileComplete && currentUser.type === 'adoptante') {
            const compat = calculateCompatibility(pet, currentUser.profileData);
            if (compat.score > 0) {
                compatibilityHTML = `
                    <div class="alert alert-success">
                        <strong>💝 Compatibilidad: ${compat.score}%</strong>
                        <ul style="margin-top: 10px; padding-left: 20px; margin-bottom: 0;">
                            ${compat.reasons.map(r => `<li>${r}</li>`).join('')}
                        </ul>
                    </div>
                `;
            }
        }

        content.innerHTML = `
            <img src="${pet.image}" alt="${pet.name}" style="width: 100%; height: 300px; object-fit: cover; border-radius: 12px; margin-bottom: 20px;" onerror="this.src='https://via.placeholder.com/600x300/e0f7ff/0077b6?text=${pet.species === 'perro' ? '🐕' : '🐈'}'">
            <h2>${pet.name}</h2>
            ${compatibilityHTML}
            <div class="pet-details-grid">
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Especie</div>
                    <div class="pet-detail-value">${pet.species === 'perro' ? '🐕 Perro' : '🐈 Gato'}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Raza</div>
                    <div class="pet-detail-value">${pet.breed}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Edad</div>
                    <div class="pet-detail-value">${pet.age.years} año${pet.age.years !== 1 ? 's' : ''} ${pet.age.months > 0 ? pet.age.months + ' meses' : ''}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Género</div>
                    <div class="pet-detail-value">${pet.gender === 'macho' ? 'Macho' : 'Hembra'}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Tamaño</div>
                    <div class="pet-detail-value">${pet.size}</div>
                </div>
                 <div class="pet-detail-item">
                    <div class="pet-detail-label">Energía</div>
                    <div class="pet-detail-value">${pet.energy}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Vacunado</div>
                    <div class="pet-detail-value">${pet.vaccinated ? '✅ Sí' : '❌ No'}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Esterilizado</div>
                    <div class="pet-detail-value">${pet.sterilized ? '✅ Sí' : '❌ No'}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Fundación</div>
                    <div class="pet-detail-value">${pet.fundacion}</div>
                </div>
                <div class="pet-detail-item">
                    <div class="pet-detail-label">Ubicación (CP)</div>
                    <div class="pet-detail-value">${pet.cp}</div>
                </div>
            </div>
            <div style="margin-top: 20px;">
                <h3>Comportamiento</h3>
                <p style="color: #666;">${pet.behavior}</p>
            </div>
            <div style="margin-top: 20px;">
                <h3>Estado de Salud</h3>
                <p style="color: #666;">${pet.health}</p>
            </div>
            ${pet.special ? `
                <div style="margin-top: 20px;">
                    <h3>Señas Particulares</h3>
                    <p style="color: #666;">${pet.special}</p>
                </div>
            ` : ''}
            ${(currentUser?.type === 'adoptante' && pet.available) ? `
                <button class="btn mt-20" onclick="startAdoptionRequest(${pet.id})">💝 Solicitar Adopción</button>
            ` : ''}
             ${!pet.available ? `
                <div class="alert alert-danger mt-20">Esta mascota ya ha sido adoptada.</div>
            ` : ''}
        `;

        showModal('modal-pet-details');
    }

    function startAdoptionRequest(petId) {
        if (!currentUser || currentUser.type !== 'adoptante') {
            alert('Debes iniciar sesión como adoptante');
            return;
        }

        if (!currentUser.profileComplete) {
            alert('Debes completar tu perfil antes de solicitar adopción');
            hideAllModals();
            showAdoptanteTab('perfil-adoptante');
            editProfile(); // Abre el modal de perfil
            return;
        }
        
        // Verificar si ya existe una solicitud para esta mascota
        const existingRequest = adoptionRequests.find(r => 
            r.adoptanteId === currentUser.id && 
            r.petId === petId &&
            (r.status === 'pendiente' || r.status === 'aprobada')
        );

        if (existingRequest) {
            alert('Ya tienes una solicitud activa para esta mascota.');
            return;
        }

        const activeSolicitudes = adoptionRequests.filter(r => 
            r.adoptanteId === currentUser.id && 
            r.status === 'pendiente'
        );

        if (activeSolicitudes.length >= 3) {
            alert('Has alcanzado el límite de 3 solicitudes activas. Espera a que se resuelvan para enviar más.');
            return;
        }

        const pet = pets.find(p => p.id === petId);
        if (!pet) return;

        const content = document.getElementById('adoption-request-content');
        content.innerHTML = `
            <div class="alert alert-info">
                <strong>Mascota:</strong> ${pet.name}<br>
                <strong>Fundación:</strong> ${pet.fundacion}
            </div>
            <p>Al enviar esta solicitud, la fundación recibirá tu perfil completo y podrá contactarte.</p>
            <div class="input-group">
                <label>Mensaje para la fundación (opcional)</label>
                <textarea id="adoption-message" rows="4" placeholder="Cuéntales por qué quieres adoptar a ${pet.name}..."></textarea>
            </div>
            <button class="btn" onclick="submitAdoptionRequest(${pet.id})">Enviar Solicitud</button>
        `;

        hideAllModals();
        showModal('modal-adoption-request');
    }

    window.submitAdoptionRequest = function(petId) {
        const message = document.getElementById('adoption-message').value;
        const pet = pets.find(p => p.id === petId);
        
        const request = {
            id: nextRequestId++,
            petId: petId,
            adoptanteId: currentUser.id,
            fundacionId: pet.fundacionId,
            message: message,
            status: 'pendiente',
            createdAt: new Date(),
            adoptanteProfile: { ...currentUser.profileData }, // Copia el perfil en el momento de la solicitud
            adoptanteName: currentUser.name,
            adoptanteEmail: currentUser.email,
            adoptantePhone: currentUser.phone
        };

        adoptionRequests.push(request);

        // Notificar a la fundación
        addNotification(
            pet.fundacionId,
            'info',
            'Nueva Solicitud de Adopción',
            `${currentUser.name} ha solicitado adoptar a ${pet.name}`
        );
        // Notificar al usuario (confirmación)
        addNotification(
            currentUser.id,
            'success',
            'Solicitud Enviada',
            `Tu solicitud para ${pet.name} ha sido enviada a ${pet.fundacion}.`
        );


        alert('¡Solicitud enviada! La fundación revisará tu perfil y se pondrá en contacto contigo.');
        hideAllModals();
        renderAdoptanteSolicitudes();
        document.getElementById('solicitudes-count').textContent = adoptionRequests.filter(r => r.adoptanteId === currentUser.id).length;
        showAdoptanteTab('mis-solicitudes');
    };

    function renderAdoptanteSolicitudes() {
        if (!currentUser || currentUser.type !== 'adoptante') return;

        const solicitudesList = document.getElementById('solicitudes-list');
        const userRequests = adoptionRequests.filter(r => r.adoptanteId === currentUser.id);

        if (userRequests.length === 0) {
            solicitudesList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📋</div>
                    <div class="empty-state-text">No has enviado solicitudes aún</div>
                </div>
            `;
            return;
        }

        solicitudesList.innerHTML = userRequests.reverse().map(req => {
            const pet = pets.find(p => p.id === req.petId);
            if (!pet) return ''; // Manejar caso de mascota borrada
            return `
                <div class="request-card">
                    <div class="request-header">
                        <div class="request-title">Solicitud por ${pet.name}</div>
                        <span class="status-badge ${req.status}">${getStatusText(req.status)}</span>
                    </div>
                    <div class="request-info">📅 Enviada: ${new Date(req.createdAt).toLocaleDateString()}</div>
                    <div class="request-info">🏢 Fundación: ${pet.fundacion}</div>
                    ${req.message ? `<div class="request-info">💬 Tu Mensaje: "${req.message}"</div>` : ''}
                    
                    ${req.status === 'aprobada' ? `
                        <div class="alert alert-success mt-20">
                            ¡Felicidades! Tu solicitud fue aprobada. La fundación se pondrá en contacto contigo.
                        </div>
                    ` : ''}
                    ${req.status === 'rechazada' && req.rejectionReason ? `
                        <div class="alert alert-danger mt-20">
                            <strong>Motivo del rechazo:</strong> ${req.rejectionReason}
                        </div>
                    ` : ''}
                </div>
            `;
        }).join('');
    }

    // ========================================
    // PARTE 4/5: PANTALLA FUNDACIÓN Y DONADOR
    // ========================================

    // ========================================
    // PANTALLA FUNDACIÓN
    // ========================================
    function renderFundacionScreen() {
        if (!currentUser || currentUser.type !== 'fundacion') return;

        renderFundacionPets();
        renderFundacionSolicitudes();
        renderFundacionDonaciones();
        
        // Asegurar que la pestaña correcta esté visible
        showFundacionTab('pets');
    }

    function renderFundacionPets() {
        const grid = document.getElementById('fundacion-pets-list');
        const fundacionPets = pets.filter(p => p.fundacionId === currentUser.id);

        if (fundacionPets.length === 0) {
            grid.innerHTML = `
                <div class="empty-state" style="grid-column: 1 / -1;">
                    <div class="empty-state-icon">🐾</div>
                    <div class="empty-state-text">No has agregado mascotas aún</div>
                    <button class="btn mt-20" onclick="showAddPetModal()" style="width:auto;">Agregar Mascota</button>
                </div>
            `;
            return;
        }

        grid.innerHTML = fundacionPets.map(pet => `
            <div class="pet-card">
                <img src="${pet.image}" alt="${pet.name}" class="pet-card-image" onerror="this.src='https://via.placeholder.com/400x220/e0f7ff/0077b6?text=${pet.species === 'perro' ? '🐕' : '🐈'}'">
                <div class="pet-card-badge ${pet.available ? '' : 'adopted'}">${pet.available ? 'Disponible' : 'Adoptado'}</div>
                <div class="pet-card-content">
                    <div class="pet-card-name">${pet.name}</div>
                    <div class="pet-card-info"><strong>Raza:</strong> ${pet.breed}</div>
                    <div class="pet-card-info"><strong>Edad:</strong> ${pet.age.years} año${pet.age.years !== 1 ? 's' : ''}</div>
                    <div class="pet-card-info"><strong>Vacunado:</strong> ${pet.vaccinated ? '✅' : '❌'}</div>
                    <div class="pet-card-info"><strong>Esterilizado:</strong> ${pet.sterilized ? '✅' : '❌'}</div>
                    <div class="pet-card-actions">
                        <button class="btn btn-small btn-secondary" onclick="editPet(${pet.id})">Editar</button>
                        ${pet.available ? `<button class="btn btn-small btn-danger" onclick="markAsAdopted(${pet.id})">Marcar Adoptado</button>` : ''}
                    </div>
                </div>
            </div>
        `).join('');
    }

    // Exportar al scope global para onclick
    window.markAsAdopted = function(petId) {
        if (confirm('¿Marcar esta mascota como adoptada? Esta acción no se puede deshacer.')) {
            const pet = pets.find(p => p.id === petId);
            if (pet) {
                pet.available = false;
                
                // Rechazar solicitudes pendientes para esta mascota
                adoptionRequests.forEach(req => {
                    if (req.petId === petId && req.status === 'pendiente') {
                        req.status = 'rechazada';
                        req.rejectionReason = 'La mascota ya ha sido adoptada.';
                        addNotification(
                            req.adoptanteId,
                            'error',
                            'Solicitud Rechazada',
                            `Tu solicitud para ${pet.name} fue rechazada porque ya fue adoptado.`
                        );
                    }
                });

                renderFundacionPets();
                renderFundacionSolicitudes(); // Para actualizar los contadores y estados
            }
        }
    };

    function renderFundacionSolicitudes() {
        if (!currentUser || currentUser.type !== 'fundacion') return;

        const solicitudesList = document.getElementById('fundacion-solicitudes-list');
        const fundacionRequests = adoptionRequests.filter(r => r.fundacionId === currentUser.id);

        document.getElementById('fund-solicitudes-count').textContent = fundacionRequests.filter(r => r.status === 'pendiente').length;

        if (fundacionRequests.length === 0) {
            solicitudesList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📋</div>
                    <div class="empty-state-text">No hay solicitudes aún</div>
                </div>
            `;
            return;
        }

        solicitudesList.innerHTML = fundacionRequests.reverse().map(req => {
            const pet = pets.find(p => p.id === req.petId);
            if (!pet) return ''; // Manejar caso de mascota borrada
            return `
                <div class="request-card">
                    <div class="request-header">
                        <div class="request-title">Solicitud para ${pet.name}</div>
                        <span class="status-badge ${req.status}">${getStatusText(req.status)}</span>
                    </div>
                    <div class="request-info">👤 Solicitante: ${req.adoptanteName}</div>
                    <div class="request-info">📧 Email: ${req.adoptanteEmail}</div>
                    <div class="request-info">📞 Teléfono: ${req.adoptantePhone}</div>
                    <div class="request-info">📅 Enviada: ${new Date(req.createdAt).toLocaleDateString()}</div>
                    ${req.message ? `<div class="request-info">💬 Mensaje: "${req.message}"</div>` : ''}
                    
                    ${req.status === 'pendiente' ? `
                        <div class="request-actions">
                            <button class="btn btn-small btn-secondary" onclick="viewAdoptanteProfile(${req.id})">Ver Perfil</button>
                            <button class="btn btn-small" onclick="approveRequest(${req.id})">Aprobar</button>
                            <button class="btn btn-small btn-danger" onclick="rejectRequest(${req.id})">Rechazar</button>
                        </div>
                    ` : ''}
                    ${req.status === 'rechazada' && req.rejectionReason ? `
                        <div class="alert alert-danger mt-20">
                            <strong>Motivo del rechazo:</strong> ${req.rejectionReason}
                        </div>
                    ` : ''}
                     ${req.status === 'aprobada' ? `
                        <div class="alert alert-success mt-20">
                            Aprobada. Te has comprometido a contactar al adoptante.
                        </div>
                    ` : ''}
                </div>
            `;
        }).join('');
    }

window.viewAdoptanteProfile = function(requestId) {
    const request = adoptionRequests.find(r => r.id === requestId);
    if (!request) return;

    const profile = request.adoptanteProfile;
    const content = document.getElementById('adoptante-profile-content');

    const ninosTexto = (Array.isArray(profile.ninos_rango) && profile.ninos_rango.length > 0)
        ? profile.ninos_rango.join(', ')
        : 'No especificado';

    const otrasMascotasTexto = (Array.isArray(profile.otras_mascotas) && profile.otras_mascotas.length > 0)
        ? profile.otras_mascotas.join(', ') + (profile.otras_mascotas_detalle ? ` (${profile.otras_mascotas_detalle})` : '')
        : 'No especificado';

    content.innerHTML = `
        <h2>Perfil de ${request.adoptanteName}</h2>

        <div class="profile-section">
            <h3>Contacto</h3>
            <div class="profile-item"><span class="profile-label">Nombre:</span><span class="profile-value">${profile.nombre}</span></div>
            <div class="profile-item"><span class="profile-label">Email:</span><span class="profile-value">${request.adoptanteEmail}</span></div>
            <div class="profile-item"><span class="profile-label">Teléfono:</span><span class="profile-value">${request.adoptantePhone}</span></div>
            <div class="profile-item"><span class="profile-label">Teléfono móvil (perfil):</span><span class="profile-value">${profile.tel_movil}</span></div>
        </div>

        <div class="profile-section">
            <h3>📍 Dirección</h3>
            <div class="profile-item"><span class="profile-label">Código Postal:</span><span class="profile-value">${profile.cp}</span></div>
            <div class="profile-item"><span class="profile-label">Estado:</span><span class="profile-value">${profile.estado}</span></div>
            <div class="profile-item"><span class="profile-label">Municipio:</span><span class="profile-value">${profile.municipio}</span></div>
            <div class="profile-item"><span class="profile-label">Colonia:</span><span class="profile-value">${profile.asentamiento}</span></div>
            <div class="profile-item"><span class="profile-label">Calle:</span><span class="profile-value">${profile.calle} ${profile.num_ext}${profile.num_int ? ' Int. ' + profile.num_int : ''}</span></div>
        </div>

        <div class="profile-section">
            <h3>🏠 Hogar y Vivienda</h3>
            <div class="profile-item"><span class="profile-label">Tipo de vivienda:</span><span class="profile-value">${profile.tipo_vivienda}</span></div>
            <div class="profile-item"><span class="profile-label">Situación de vivienda:</span><span class="profile-value">${profile.situacion_vivienda}</span></div>
            <div class="profile-item"><span class="profile-label">Espacio cercado:</span><span class="profile-value">${profile.espacio_cercado}</span></div>
            <div class="profile-item"><span class="profile-label">Adultos en el hogar:</span><span class="profile-value">${profile.adultos_hogar}</span></div>
            <div class="profile-item"><span class="profile-label">Personas en el hogar:</span><span class="profile-value">${profile.personas_hogar}</span></div>
            <div class="profile-item"><span class="profile-label">Niños en el hogar:</span><span class="profile-value">${ninosTexto}</span></div>
            <div class="profile-item"><span class="profile-label">Otras mascotas:</span><span class="profile-value">${otrasMascotasTexto}</span></div>
        </div>

        <div class="profile-section">
            <h3>🐾 Estilo de Vida y Compromiso</h3>
            <div class="profile-item"><span class="profile-label">Experiencia con mascotas:</span><span class="profile-value">${profile.experiencia_previa === 'si' ? 'Sí' : 'No'} (${profile.nivel_experiencia})</span></div>
            <div class="profile-item"><span class="profile-label">Horas fuera de casa:</span><span class="profile-value">${profile.horas_fuera}</span></div>
            <div class="profile-item"><span class="profile-label">Nivel de actividad buscado:</span><span class="profile-value">${profile.nivel_actividad}</span></div>
            <div class="profile-item"><span class="profile-label">Tiempo disponible diario:</span><span class="profile-value">${profile.tiempo_dedicado}</span></div>
            <div class="profile-item"><span class="profile-label">Acepta gastos veterinarios:</span><span class="profile-value">${profile.gastos_vet === 'si' ? 'Sí' : 'No'}</span></div>
            <div class="profile-item"><span class="profile-label">Compromiso de esterilización:</span><span class="profile-value">${profile.compromiso_esterilizacion === 'si' ? 'Sí' : 'No'}</span></div>
            <div class="profile-item"><span class="profile-label">Motivo adopción:</span><span class="profile-value">${profile.motivo_adopcion}</span></div>
            <div class="profile-item"><span class="profile-label">Si sus circunstancias cambian:</span><span class="profile-value">${profile.que_haria_cambios}</span></div>
        </div>

        <div class="profile-section">
            <h3>🩺 Referencia Veterinaria</h3>
            <div class="profile-item"><span class="profile-label">Veterinario:</span><span class="profile-value">${profile.veterinario || 'No especificado'}</span></div>
        </div>
    `;
    
    showModal('modal-adoptante-profile');
};

    window.approveRequest = function(requestId) {
        if (confirm('¿Aprobar esta solicitud? Te comprometes a contactar al adoptante.')) {
            const request = adoptionRequests.find(r => r.id === requestId);
            if (!request) return;

            request.status = 'aprobada';
            
            const pet = pets.find(p => p.id === request.petId);
            
            // Opcional: Marcar como no disponible. Lo haré automático para simplificar.
            pet.available = false; 

            addNotification(
                request.adoptanteId,
                'success',
                '¡Solicitud Aprobada!',
                `¡Felicidades! Tu solicitud para adoptar a ${pet.name} ha sido aprobada. La fundación ${currentUser.name} se pondrá en contacto contigo.`
            );
            
            // Rechazar otras solicitudes pendientes para ESTA MASCOTA
             adoptionRequests.forEach(req => {
                if (req.petId === pet.id && req.status === 'pendiente') {
                    req.status = 'rechazada';
                    req.rejectionReason = 'La mascota ya ha sido adoptada por otra persona.';
                    addNotification(
                        req.adoptanteId,
                        'error',
                        'Solicitud Rechazada',
                        `Tu solicitud para ${pet.name} fue rechazada porque ya fue adoptado.`
                    );
                }
            });

            renderFundacionSolicitudes();
            renderFundacionPets(); // Para que la mascota aparezca como "Adoptado"
        }
    };

    window.rejectRequest = function(requestId) {
        const reason = prompt('Ingresa un motivo breve para el rechazo (esto será visible para el adoptante):');
        if (reason && reason.trim() !== '') {
            const request = adoptionRequests.find(r => r.id === requestId);
            if (!request) return;

            request.status = 'rechazada';
            request.rejectionReason = reason;

            const pet = pets.find(p => p.id === request.petId);

            addNotification(
                request.adoptanteId,
                'error',
                'Solicitud Rechazada',
                `Tu solicitud para ${pet.name} fue rechazada. Motivo: ${reason}`
            );

            renderFundacionSolicitudes();
        } else if (reason !== null) { // Si no canceló el prompt
            alert('Debes ingresar un motivo para rechazar la solicitud.');
        }
    };

    function renderFundacionDonaciones() {
        const donacionesList = document.getElementById('fundacion-donaciones-list');
        const fundacionDonations = donations.filter(d => d.fundacionId === currentUser.id);

        if (fundacionDonations.length === 0) {
            donacionesList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">💰</div>
                    <div class="empty-state-text">Aún no has recibido donaciones</div>
                </div>
            `;
            return;
        }

        donacionesList.innerHTML = fundacionDonations.reverse().map(don => `
            <div class="request-card">
                <div class="request-header">
                    <div class="request-title">$${don.amount.toFixed(2)} MXN</div>
                    <span class="status-badge completada">Completada</span>
                </div>
                <div class="request-info">👤 Donador: ${don.donadorName}</div>
                <div class="request-info">📅 Fecha: ${new Date(don.createdAt).toLocaleDateString()}</div>
                ${don.message ? `<div class="request-info">💬 Mensaje: "${don.message}"</div>` : ''}
            </div>
        `).join('');
    }

    // ========================================
    // PANTALLA DONADOR
    // ========================================
    function renderDonadorScreen() {
        if (!currentUser || currentUser.type !== 'donador') return;
        
        renderFundacionesParaDonar();
        renderDonadorHistorial();
    }

    function renderFundacionesParaDonar() {
        const grid = document.getElementById('fundaciones-grid');
        const fundaciones = users.filter(u => u.type === 'fundacion');

        if (fundaciones.length === 0) {
            grid.innerHTML = `<p>No hay fundaciones registradas aún.</p>`;
            return;
        }

        grid.innerHTML = fundaciones.map(fund => `
            <div class="fundacion-card">
                <div class="fundacion-card-name">${fund.fundacionName || fund.name}</div>
                <div class="fundacion-card-email">${fund.email}</div>
                <div class="fundacion-card-phone">${fund.phone}</div>
                <button class="btn btn-small" onclick="showDonationModal(${fund.id})">Donar</button>
            </div>
        `).join('');
    }
    
    function renderDonadorHistorial() {
        const historialList = document.getElementById('donador-historial-list');
        const userDonations = donations.filter(d => d.donadorId === currentUser.id);

        if (userDonations.length === 0) {
            historialList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📜</div>
                    <div class="empty-state-text">No has realizado donaciones</div>
                </div>
            `;
            return;
        }
        
        historialList.innerHTML = userDonations.reverse().map(don => {
            const fundacion = users.find(u => u.id === don.fundacionId);
            return `
                <div class="request-card">
                    <div class="request-header">
                        <div class="request-title">$${don.amount.toFixed(2)} MXN</div>
                        <span class="status-badge completada">Realizada</span>
                    </div>
                    <div class="request-info">🏢 Fundación: ${fundacion ? fundacion.name : 'Desconocida'}</div>
                    <div class="request-info">📅 Fecha: ${new Date(don.createdAt).toLocaleDateString()}</div>
                     ${don.message ? `<div class="request-info">💬 Tu Mensaje: "${don.message}"</div>` : ''}
                </div>
            `;
        }).join('');
    }

    window.showDonationModal = function(fundacionId) {
        const fundacion = users.find(u => u.id === fundacionId);
        if (!fundacion) return;
        
        document.getElementById('donation-fundacion-name').textContent = fundacion.name;
        document.getElementById('donation-form').dataset.fundacionId = fundacionId;
        document.getElementById('donation-form').reset();
        
        showModal('modal-donation');
    };

    // ========================================
    // PARTE 5/5: FORMULARIOS Y EVENT LISTENERS
    // ========================================

    // ========================================
    // MANEJO DE FORMULARIOS (PERFIL, MASCOTA)
    // ========================================
    
    function setupCPListener() {
        const cpInput = document.getElementById('profile-cp');
        if (!cpInput) return; // Salir si el elemento no existe
        
        const asentamientoSelect = document.getElementById('profile-asentamiento');

        cpInput.addEventListener('change', () => {
            const cp = cpInput.value;
            if (cp.length !== 5) return; // No buscar si no tiene 5 dígitos
            
            const data = dataCodigos[cp];

            asentamientoSelect.innerHTML = '<option value="">Selecciona una colonia</option>';
            document.getElementById('profile-estado').value = '';
            document.getElementById('profile-municipio').value = '';

            if (data && data.length > 0) {
                document.getElementById('profile-estado').value = data[0].estado;
                document.getElementById('profile-municipio').value = data[0].municipio;

                data.forEach(item => {
                    const option = document.createElement('option');
                    option.value = item.asentamiento;
                    option.textContent = `${item.asentamiento} (${item.tipo_asentamiento})`;
                    asentamientoSelect.appendChild(option);
                });
            } else {
                alert('Código Postal no encontrado.');
            }
        });
    }

window.editProfile = function() {
    const form = document.getElementById('profile-form');
    form.reset();

    // Limpiar campos deshabilitados de dirección
    document.getElementById('profile-estado').value = '';
    document.getElementById('profile-municipio').value = '';
    document.getElementById('profile-asentamiento').innerHTML = '<option value="">-- Esperando código postal --</option>';

    if (currentUser.profileComplete && currentUser.profileData) {
        const profile = currentUser.profileData;

        // Dirección
        form['profile-cp'].value = profile.cp;

        const data = dataCodigos[profile.cp];
        const asentamientoSelect = document.getElementById('profile-asentamiento');
        asentamientoSelect.innerHTML = '<option value="">Selecciona una colonia</option>';
        if (data) {
            data.forEach(item => {
                const option = document.createElement('option');
                option.value = item.asentamiento;
                option.textContent = `${item.asentamiento} (${item.tipo_asentamiento})`;
                asentamientoSelect.appendChild(option);
            });
        }

        document.getElementById('profile-estado').value = profile.estado || '';
        document.getElementById('profile-municipio').value = profile.municipio || '';
        form['profile-asentamiento'].value = profile.asentamiento;
        form['profile-calle'].value = profile.calle;
        form['profile-num-ext'].value = profile.num_ext;
        form['profile-num-int'].value = profile.num_int || '';

        // I. Personal
        form['profile-nombre'].value = profile.nombre || '';
        form['profile-edad'].value = profile.edad || '';
        form['profile-tel-movil'].value = profile.tel_movil || '';
        form['profile-tel-fijo'].value = profile.tel_fijo || '';
        form['profile-email'].value = profile.email || '';

        // II. Vivienda
        form['profile-tipo-vivienda'].value = profile.tipo_vivienda || '';
        form['profile-situacion-vivienda'].value = profile.situacion_vivienda || '';
        form['profile-contacto-arrendador'].value = profile.contacto_arrendador || '';
        form['profile-espacio-cercado'].value = profile.espacio_cercado || '';

        // III. Hogar y experiencia
        form['profile-adultos-hogar'].value = profile.adultos_hogar || '';
        form['profile-personas-hogar'].value = profile.personas_hogar || '';

        // Niños (checkboxes)
        if (Array.isArray(profile.ninos_rango)) {
            form.querySelectorAll('input[name="profile-ninos-rango"]').forEach(ch => {
                ch.checked = profile.ninos_rango.includes(ch.value);
            });
        }

        // Otras mascotas (checkboxes)
        if (Array.isArray(profile.otras_mascotas)) {
            form.querySelectorAll('input[name="profile-otras-mascotas"]').forEach(ch => {
                ch.checked = profile.otras_mascotas.includes(ch.value);
            });
        }
        form['profile-otras-mascotas-detalle'].value = profile.otras_mascotas_detalle || '';

        form['profile-experiencia-previa'].value = profile.experiencia_previa || '';
        form['profile-nivel-experiencia'].value = profile.nivel_experiencia || '';
        form['profile-horas-fuera'].value = profile.horas_fuera || '';

        // IV. Compromiso
        form['profile-nivel-actividad'].value = profile.nivel_actividad || '';
        form['profile-gastos-vet'].value = profile.gastos_vet || '';
        form['profile-compromiso-esterilizacion'].value = profile.compromiso_esterilizacion || '';
        form['profile-tiempo-dedicado'].value = profile.tiempo_dedicado || '';
        form['profile-motivo-adopcion'].value = profile.motivo_adopcion || '';
        form['profile-que-haria-cambios'].value = profile.que_haria_cambios || '';

        // V. Referencias
        form['profile-veterinario'].value = profile.veterinario || '';
    }

    showModal('modal-profile');
};

    window.showAddPetModal = function() {
        const form = document.getElementById('pet-form');
        form.reset();
        form.dataset.petId = ''; // Limpiar ID de mascota
        document.getElementById('pet-form-title').textContent = 'Agregar Nueva Mascota';
        showModal('modal-pet-form');
    };

    window.editPet = function(petId) {
        const pet = pets.find(p => p.id === petId);
        if (!pet) return;

        const form = document.getElementById('pet-form');
        form.reset();
        form.dataset.petId = pet.id;
        document.getElementById('pet-form-title').textContent = 'Editar Mascota';

        form['pet-name'].value = pet.name;
        form['pet-species'].value = pet.species;
        form['pet-breed'].value = pet.breed;
        form['pet-age-years'].value = pet.age.years;
        form['pet-age-months'].value = pet.age.months;
        form['pet-gender'].value = pet.gender;
        form['pet-size'].value = pet.size;
        form['pet-energy'].value = pet.energy;
        form['pet-behavior'].value = pet.behavior;
        form['pet-health'].value = pet.health;
        form['pet-special'].value = pet.special || '';
        form['pet-image'].value = pet.image;
        form['pet-cp'].value = pet.cp;
        form['pet-vaccinated'].checked = pet.vaccinated;
        form['pet-sterilized'].checked = pet.sterilized;
        
        showModal('modal-pet-form');
    };

    // ========================================
    // TAB SCRIPTING
    // ========================================
    
    window.showAdoptanteTab = function(tabName) {
        document.querySelectorAll('.adoptante-tab-content').forEach(tab => {
            tab.classList.remove('active');
            tab.classList.add('hidden');
        });
        document.querySelectorAll('.tab-link-adoptante').forEach(link => {
            link.classList.remove('active');
        });
        
        document.getElementById(`adoptante-${tabName}`).classList.remove('hidden');
        document.getElementById(`adoptante-${tabName}`).classList.add('active');
        document.querySelector(`.tab-link-adoptante[data-tab="${tabName}"]`).classList.add('active');
    };

    window.showFundacionTab = function(tabName) {
        document.querySelectorAll('.fundacion-tab-content').forEach(tab => {
            tab.classList.remove('active');
            tab.classList.add('hidden');
        });
         document.querySelectorAll('.tab-link-fundacion').forEach(link => {
            link.classList.remove('active');
        });
        
        document.getElementById(`fundacion-${tabName}`).classList.remove('hidden');
        document.getElementById(`fundacion-${tabName}`).classList.add('active');
        document.querySelector(`.tab-link-fundacion[data-tab="${tabName}"]`).classList.add('active');
    };
    
    // ========================================
    // FILTROS
    // ========================================
    window.applyPetFilters = function() {
        const filters = {
            species: document.getElementById('filter-species').value,
            age: document.getElementById('filter-age').value,
            size: document.getElementById('filter-size').value,
            compatibility: document.getElementById('filter-compatibility').checked
        };
        
        // Limpiar valores vacíos
        Object.keys(filters).forEach(key => {
            if (filters[key] === '') delete filters[key];
        });
        
        renderPetsGrid(filters);
    };

    // ========================================
    // EVENT LISTENERS (DOM)
    // ========================================
    
    // --- Formularios ---
    document.getElementById('login-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const email = e.target['login-email'].value;
        const password = e.target['login-password'].value;
        if (!login(email, password)) {
            alert('Email o contraseña incorrectos');
        } else {
            e.target.reset();
        }
    });

    document.getElementById('register-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const type = e.target['register-type'].value;
        const name = e.target['register-name'].value;
        const email = e.target['register-email'].value;
        const phone = e.target['register-phone'].value;
        const password = e.target['register-password'].value;

        const userData = { type, name, email, phone, password };
        
        if (type === 'fundacion') {
            userData.fundacionName = e.target['register-fundacion-name'].value;
            // Podrías añadir más validación aquí si los campos son obligatorios
        }

        if (register(userData)) {
            e.target.reset();
            document.getElementById('fundacion-extra').classList.add('hidden');
        }
    });

    // Listener para mostrar campos de fundación en el registro
    document.getElementById('reg-type').addEventListener('change', (e) => {
        const fundacionFields = document.getElementById('fundacion-extra');
        if (e.target.value === 'fundacion') {
            fundacionFields.classList.remove('hidden');
            fundacionFields.querySelectorAll('input').forEach(input => input.required = true);
        } else {
            fundacionFields.classList.add('hidden');
            fundacionFields.querySelectorAll('input').forEach(input => input.required = false);
        }
    });

document.getElementById('profile-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);

    const profileData = {
        // Dirección
        cp: formData.get('profile-cp'),
        estado: formData.get('profile-estado'),
        municipio: formData.get('profile-municipio'),
        asentamiento: formData.get('profile-asentamiento'),
        calle: formData.get('profile-calle'),
        num_ext: formData.get('profile-num-ext'),
        num_int: formData.get('profile-num-int') || '',

        // I. Información personal y contacto
        nombre: formData.get('profile-nombre'),
        edad: formData.get('profile-edad'),
        tel_movil: formData.get('profile-tel-movil'),
        tel_fijo: formData.get('profile-tel-fijo') || '',
        email: formData.get('profile-email'),

        // II. Vivienda
        tipo_vivienda: formData.get('profile-tipo-vivienda'),
        situacion_vivienda: formData.get('profile-situacion-vivienda'),
        contacto_arrendador: formData.get('profile-contacto-arrendador') || '',
        espacio_cercado: formData.get('profile-espacio-cercado'),

        // III. Hogar y experiencia
        adultos_hogar: formData.get('profile-adultos-hogar'),
        personas_hogar: formData.get('profile-personas-hogar'),
        ninos_rango: [...form.querySelectorAll('input[name="profile-ninos-rango"]:checked')].map(ch => ch.value),
        otras_mascotas: [...form.querySelectorAll('input[name="profile-otras-mascotas"]:checked')].map(ch => ch.value),
        otras_mascotas_detalle: formData.get('profile-otras-mascotas-detalle') || '',
        experiencia_previa: formData.get('profile-experiencia-previa'),
        nivel_experiencia: formData.get('profile-nivel-experiencia'),
        horas_fuera: formData.get('profile-horas-fuera'),

        // IV. Compromiso y estilo de vida
        nivel_actividad: formData.get('profile-nivel-actividad'),
        gastos_vet: formData.get('profile-gastos-vet'),
        compromiso_esterilizacion: formData.get('profile-compromiso-esterilizacion'),
        tiempo_dedicado: formData.get('profile-tiempo-dedicado'),
        motivo_adopcion: formData.get('profile-motivo-adopcion'),
        que_haria_cambios: formData.get('profile-que-haria-cambios'),

        // V. Referencia
        veterinario: formData.get('profile-veterinario') || ''
    };

    // Validación básica de campos obligatorios
    const requiredKeys = [
        'cp','asentamiento','calle','num_ext','nombre','edad',
        'tel_movil','email','tipo_vivienda','situacion_vivienda',
        'espacio_cercado','adultos_hogar','personas_hogar',
        'experiencia_previa','nivel_experiencia','horas_fuera',
        'nivel_actividad','gastos_vet','compromiso_esterilizacion',
        'tiempo_dedicado','motivo_adopcion','que_haria_cambios'
    ];

    for (const key of requiredKeys) {
        if (!profileData[key] || profileData[key].length === 0) {
            alert('Por favor, completa todos los campos obligatorios.');
            return;
        }
    }

    currentUser.profileData = profileData;
    currentUser.profileComplete = true;

    alert('¡Perfil actualizado con éxito!');
    hideAllModals();
    renderAdoptanteScreen(); // Refrescar vista
});


    document.getElementById('pet-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const form = e.target;
        const petId = form.dataset.petId ? parseInt(form.dataset.petId) : null;

        const petData = {
            name: form['pet-name'].value,
            species: form['pet-species'].value,
            breed: form['pet-breed'].value,
            age: { 
                years: parseInt(form['pet-age-years'].value) || 0, 
                months: parseInt(form['pet-age-months'].value) || 0
            },
            gender: form['pet-gender'].value,
            size: form['pet-size'].value,
            energy: form['pet-energy'].value,
            behavior: form['pet-behavior'].value,
            health: form['pet-health'].value,
            special: form['pet-special'].value,
            image: form['pet-image'].value,
            cp: form['pet-cp'].value,
            vaccinated: form['pet-vaccinated'].checked,
            sterilized: form['pet-sterilized'].checked,
            fundacion: currentUser.name,
            fundacionId: currentUser.id
            // 'available' se maneja diferente
        };

        if (petId) {
            // Editar
            const petIndex = pets.findIndex(p => p.id === petId);
            if (petIndex !== -1) {
                // Conservar el estado 'available' existente al editar
                const oldPet = pets[petIndex];
                pets[petIndex] = { ...oldPet, ...petData };
            }
        } else {
            // Nuevo
            petData.id = nextPetId++;
            petData.available = true; // Las mascotas nuevas siempre están disponibles
            pets.push(petData);
        }

        alert(petId ? 'Mascota actualizada' : 'Mascota agregada');
        hideAllModals();
        renderFundacionPets();
        form.reset();
    });
    
    document.getElementById('donation-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const form = e.target;
        const fundacionId = parseInt(form.dataset.fundacionId);
        const amount = parseFloat(form['donation-amount'].value);
        const message = form['donation-message'].value;
        
        if (isNaN(amount) || amount <= 0) {
            alert('Ingresa un monto válido');
            return;
        }

        const donation = {
            id: nextDonationId++,
            donadorId: currentUser.id,
            donadorName: currentUser.name,
            fundacionId: fundacionId,
            amount: amount,
            message: message,
            createdAt: new Date()
        };
        
        donations.push(donation);
        
        const fundacion = users.find(u => u.id === fundacionId);
        
        // Notificar a la fundación
        addNotification(
            fundacionId,
            'success',
            '¡Nueva Donación!',
            `${currentUser.name} te ha enviado una donación de $${amount.toFixed(2)}`
        );
        // Notificar al donador (confirmación)
         addNotification(
            currentUser.id,
            'success',
            '¡Donación Enviada!',
            `Gracias por tu donación de $${amount.toFixed(2)} a ${fundacion.name}.`
        );
        
        alert('¡Gracias por tu donación!');
        hideAllModals();
        renderDonadorHistorial();
        form.reset();
    });

    // --- Navegación y Modales ---
    document.getElementById('nav-logout').addEventListener('click', logout);
    document.getElementById('nav-notifications').addEventListener('click', showNotifications);
    document.getElementById('show-login-btn').addEventListener('click', () => showScreen('login-screen'));
    document.getElementById('show-register-btn').addEventListener('click', () => showScreen('register-screen'));
    document.getElementById('back-to-welcome-btn').addEventListener('click', () => showScreen('welcome-screen'));
    document.getElementById('back-to-welcome-btn-2').addEventListener('click', () => showScreen('welcome-screen'));

    // --- Enlaces de pie de formulario ---
    document.getElementById('footer-go-to-login').addEventListener('click', (e) => {
        e.preventDefault(); 
        showScreen('login-screen');
    });
    document.getElementById('footer-go-to-register').addEventListener('click', (e) => {
        e.preventDefault();
        showScreen('register-screen');
    });
    
    // Botón completar perfil (Adoptante)
    document.getElementById('complete-profile-btn').addEventListener('click', window.editProfile);
    
    // Botón agregar mascota (Fundación)
    document.getElementById('add-pet-btn').addEventListener('click', window.showAddPetModal);
    
    // Filtros
    document.getElementById('apply-filters-btn').addEventListener('click', window.applyPetFilters);
    document.getElementById('filter-compatibility').addEventListener('change', window.applyPetFilters); // Aplicar al marcar/desmarcar


    // Cerrar modales
    document.querySelectorAll('[data-close]').forEach(btn => {
        btn.addEventListener('click', () => {
            hideAllModals();
        });
    });
    document.getElementById('modal-overlay').addEventListener('click', hideAllModals);

    // Navegación de Pestañas (Tabs)
    document.querySelectorAll('.tab-link-adoptante').forEach(link => {
        link.addEventListener('click', () => {
            window.showAdoptanteTab(link.dataset.tab);
        });
    });
     document.querySelectorAll('.tab-link-fundacion').forEach(link => {
        link.addEventListener('click', () => {
            window.showFundacionTab(link.dataset.tab);
        });
    });

    // --- Inicialización ---
    initializePets();
    cargarDatosCodigosPostales();
    setupCPListener();
    showScreen('welcome-screen');

    // Exportar funciones globales para `onclick` en HTML
    window.viewPetDetails = viewPetDetails;
    window.startAdoptionRequest = startAdoptionRequest;
    
});