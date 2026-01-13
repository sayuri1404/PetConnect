import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def register_fundacion():
    url = f"{BASE_URL}/auth/register-fundacion"
    payload = {
        "nombre": "Fundación Patitas",
        "email": "fundacion@paw.com",
        "password": "password123",
        "telefono": "5551234567",
        "rfc": "FUN123456789",
        "direccion": "Calle de los Perritos 123",
        "descripcion": "Ayudamos a perritos de la calle"
    }
    try:
        res = requests.post(url, json=payload)
        if res.status_code == 200:
            print("Fundacion registered: fundacion@paw.com / password123")
        elif res.status_code == 400 and "exists" in res.text:
             print("Fundacion already exists: fundacion@paw.com")
        else:
            print(f"Error registering fundacion: {res.status_code} {res.text}")
    except Exception as e:
        print(f"Failed to connect: {e}")

def register_adoptante():
    url = f"{BASE_URL}/auth/register-adoptante"
    payload = {
        "nombre": "Juan Adoptante",
        "email": "juan@paw.com",
        "password": "password123",
        "telefono": "5559876543"
    }
    try:
        res = requests.post(url, json=payload)
        if res.status_code == 200:
            print("Adoptante registered: juan@paw.com / password123")
        elif res.status_code == 400 and "exists" in res.text:
             print("Adoptante already exists: juan@paw.com")
        else:
            print(f"Error registering adoptante: {res.status_code} {res.text}")
    except Exception as e:
        print(f"Failed to connect: {e}")

if __name__ == "__main__":
    register_fundacion()
    register_adoptante()
