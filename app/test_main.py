from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    reponse = client.get("/health")
    assert reponse.status_code == 200
    assert reponse.json() == {"status": "ok"}


def test_creer_puis_lire():
    reponse = client.post("/equipements", json={
        "nom": "srv-web01", "categorie": "serveur", "adresse_ip": "192.168.56.10",
    })
    assert reponse.status_code == 201
    equipement = reponse.json()
    assert equipement["nom"] == "srv-web01"

    reponse = client.get(f"/equipements/{equipement['id']}")
    assert reponse.status_code == 200


def test_equipement_introuvable():
    assert client.get("/equipements/9999").status_code == 404


def test_donnees_invalides():
    reponse = client.post("/equipements", json={"categorie": "serveur"})  # pas de nom
    assert reponse.status_code == 422
