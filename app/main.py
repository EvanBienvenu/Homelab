"""API d'inventaire de matériel : v1 du homelab."""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Inventaire Homelab", version="0.1.0")


class EquipementIn(BaseModel):
    """Ce que le client envoie pour créer un équipement."""
    nom: str
    categorie: str                 # ex. : serveur, switch, poste
    adresse_ip: str | None = None  # facultatif


class Equipement(EquipementIn):
    """Ce que l'API renvoie : les mêmes champs, plus un identifiant."""
    id: int


# Stockage en mémoire pour la v1 : tout est perdu au redémarrage
equipements: dict[int, Equipement] = {}
prochain_id = 1


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/equipements")
def lister() -> list[Equipement]:
    return list(equipements.values())


@app.post("/equipements", status_code=201)
def creer(donnees: EquipementIn) -> Equipement:
    global prochain_id
    equipement = Equipement(id=prochain_id, **donnees.model_dump())
    equipements[prochain_id] = equipement
    prochain_id += 1
    return equipement


@app.get("/equipements/{equipement_id}")
def lire(equipement_id: int) -> Equipement:
    if equipement_id not in equipements:
        raise HTTPException(status_code=404, detail="équipement introuvable")
    return equipements[equipement_id]
