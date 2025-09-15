// FUNCIONES DE NAVEGACIÓN Y VISIBILIDAD DE SECCIONES

/**
 * Oculta todas las secciones principales de la página.
 * Itera sobre una lista de IDs y les añade la clase 'hidden'.
 */
function hideAll() {
    const ids = ['home', 'form-section', 'loading', 'results', 'admin', 'pet-form'];
    ids.forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.classList.add('hidden');
        }
    });
}

/**
 * Muestra la sección del formulario de usuario.
 */
function showForm() {
    hideAll();
    document.getElementById('form-section').classList.remove('hidden');
}

/**
 * Muestra la sección de "Refugios Asociados".
 * Reutiliza el panel de admin pero cambia sus títulos.
 */
function showShelters() {
    hideAll();
    const title = document.getElementById('adminTitle');
    const subtitle = document.getElementById('adminSubtitle');
    if (title) title.textContent = 'Refugios Asociados';
    if (subtitle) subtitle.textContent = 'Alianzas, estado y gestión de refugios asociados';

    document.getElementById('admin').classList.remove('hidden');
}

/**
 * Muestra el Panel Administrativo con sus títulos originales.
 */
function showAdmin() {
    hideAll();
    const title = document.getElementById('adminTitle');
    const subtitle = document.getElementById('adminSubtitle');
    if (title) title.textContent = 'Panel Administrativo';
    if (subtitle) subtitle.textContent = 'Gestión del sistema de adopciones';

    document.getElementById('admin').classList.remove('hidden');
}

/**
 * Muestra la pantalla de inicio.
 */
function goHome() {
    hideAll();
    document.getElementById('home').classList.remove('hidden');
}

/**
 * Muestra el formulario para registrar una nueva mascota.
 */
function showPetForm() {
    hideAll();
    const petForm = document.getElementById('pet-form');
    if (petForm) petForm.classList.remove('hidden');
}

// SIMULACIÓN DE BÚSQUEDA Y PROGRESO DE ANÁLISIS

/**
 * Inicia la simulación de búsqueda.
 * Muestra la pantalla de carga y anima una barra de progreso.
 */
function startSearch() {
    hideAll();
    document.getElementById('loading').classList.remove('hidden');
    
    let progress = 40; // Simula que los primeros 2 pasos ya están completados
    let currentStep = 2;
    
    const bar = document.getElementById('progressBar');
    
    // Inicia un intervalo para actualizar la barra de progreso
    let interval = setInterval(function() {
        progress += Math.random() * 10; // Incrementa el progreso de forma aleatoria
        if (progress > 100) progress = 100;
        
        if (bar) bar.style.width = progress + '%';
        
        // Actualiza el texto de los pasos a medida que avanza el progreso
        if (progress > 60 && currentStep === 2) {
            document.getElementById('step3').innerHTML = '✅ Evaluación de experiencia requerida';
            document.getElementById('step4').innerHTML = '⏳ Análisis de presupuesto y gastos';
            currentStep++;
        } else if (progress > 80 && currentStep === 3) {
            document.getElementById('step4').innerHTML = '✅ Análisis de presupuesto y gastos';
            document.getElementById('step5').innerHTML = '⏳ Filtro de necesidades médicas especiales';
            currentStep++;
        } else if (progress >= 100 && currentStep === 4) {
            document.getElementById('step5').innerHTML = '✅ Filtro de necesidades médicas especiales';
            
            clearInterval(interval); // Detiene el intervalo
            
            // Espera un segundo y luego muestra los resultados
            setTimeout(function() {
                hideAll();
                document.getElementById('results').classList.remove('hidden');
            }, 1000);
        }
    }, 300); // El intervalo se ejecuta cada 300 milisegundos
}

// MANEJO DE EVENTOS Y FORMULARIOS DE MASCOTAS

/**
 * Escucha todos los clics en el documento para manejar botones genéricos.
 * Esto evita tener que añadir un 'onclick' a cada botón.
 * Muestra alertas simulando funcionalidades en desarrollo.
 */
document.addEventListener('click', function(e) {
    // Verifica si el elemento clickeado es un botón con texto
    if (e.target.tagName === 'BUTTON' && e.target.textContent) {
        const text = e.target.textContent.toLowerCase();
        
        // Simulación de diferentes funcionalidades basadas en el texto del botón
        if (text.includes('agendar') && !text.includes('agendando')) {
            alert('Funcionalidad de agendar cita - En desarrollo');
        } else if (text.includes('ver detalles') || text.includes('ver')) {
            alert('Mostrando detalles - En desarrollo');
        } else if (text.includes('aprobar')) {
            alert('Match aprobado - Enviando notificación a adoptante');
        } else if (text.includes('conoce por qué')) {
            alert('Análisis de compatibilidad detallado - En desarrollo');
        }
    }
});

/**
 * Valida y envía el formulario de registro de mascotas.
 * @param {Event} event - El evento de envío del formulario.
 */
function submitPetForm(event) {
    event.preventDefault(); // Evita que la página se recargue

    // Lista de IDs de campos obligatorios
    const requiredIds = [
        'petAge', 'petWeight', 'healthStatus', 'energyLevel', 
        'socialPeople', 'temperamentDescription', 'exerciseNeeds', 'housingNeeds'
    ];

    // Valida que todos los campos requeridos estén llenos
    for (const id of requiredIds) {
        const el = document.getElementById(id);
        if (!el || !String(el.value).trim()) {
            alert('Por favor, completa todos los campos marcados con *');
            if (el) el.focus(); // Pone el foco en el campo vacío
            return; // Detiene la ejecución de la función
        }
    }

    // Simulación de guardado con feedback visual en el botón
    const form = document.getElementById('petRegistrationForm');
    const submitBtn = form ? form.querySelector('button[type="submit"]') : null;
    const originalText = submitBtn ? submitBtn.textContent : '';

    if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = '🔄 Guardando...';
    }

    // Simula un retraso de red de 1 segundo
    setTimeout(() => {
        const successMessage = document.getElementById('successMessage');
        if (successMessage) {
            successMessage.style.display = 'block';
            // Hace scroll para que el mensaje sea visible
            successMessage.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }

        // Después de 1.5 segundos, restaura el botón
        setTimeout(() => {
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
            }
            // Y después de 2 segundos más, oculta el mensaje de éxito
            setTimeout(() => { if (successMessage) successMessage.style.display = 'none'; }, 2000);
        }, 1500);
    }, 1000);
}

/**
 * Limpia (resetea) los campos del formulario de registro de mascotas.
 * Pide confirmación al usuario antes de borrar los datos.
 */
function resetPetForm() {
    if (confirm('¿Deseas limpiar todos los campos del formulario?')) {
        const form = document.getElementById('petRegistrationForm');
        if (form) form.reset();
        
        // También oculta el mensaje de éxito si estuviera visible
        const successMessage = document.getElementById('successMessage');
        if (successMessage) successMessage.style.display = 'none';
    }
}