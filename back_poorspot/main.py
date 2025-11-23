import json
import os
import hashlib
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime, timedelta
from uuid import uuid4
import uvicorn

DB_FILE = "db.json"

# --- 50 SUCCÈS GAMIFIÉS (LISTE ÉTENDUE) ---
ACHIEVEMENTS_DEF = [
    # --- 1. DÉMARRAGE (2) ---
    {"id": "welcome", "name": "Bienvenue", "desc": "Créer son compte", "points": 10, "icon": "waving_hand"},
    {"id": "first_step", "name": "Premier Pas", "desc": "Terminer une première session", "points": 20, "icon": "footprint"},
    
    # --- 2. ENDURANCE (TEMPS) (5) ---
    {"id": "time_1h", "name": "Débutant", "desc": "1 heure cumulée", "points": 30, "icon": "hourglass_bottom"},
    {"id": "time_5h", "name": "Habitué", "desc": "5 heures cumulées", "points": 60, "icon": "hourglass_empty"},
    {"id": "time_10h", "name": "Pro de la rue", "desc": "10 heures cumulées", "points": 120, "icon": "hourglass_full"},
    {"id": "time_24h", "name": "Légende", "desc": "24 heures cumulées", "points": 300, "icon": "history"},
    {"id": "time_100h", "name": "Immortel", "desc": "100 heures cumulées", "points": 1000, "icon": "infinity"},
    
    # --- 3. EXPLORATION (QUANTITÉ) (5) ---
    {"id": "explorer_3", "name": "Curieux", "desc": "3 spots différents visités", "points": 50, "icon": "compass"},
    {"id": "explorer_10", "name": "Nomade", "desc": "10 spots différents visités", "points": 150, "icon": "map"},
    {"id": "explorer_15", "name": "Explorateur Ultime", "desc": "15 spots différents visités", "points": 250, "icon": "explore"}, # NEW
    {"id": "explorer_20", "name": "Vagabond", "desc": "20 spots différents visités", "points": 300, "icon": "public"},
    {"id": "jack_of_all", "name": "Polyvalent", "desc": "Visiter 1 spot de chaque catégorie", "points": 200, "icon": "category"},

    # --- 4. SPÉCIALISTE (CATÉGORIES) (9) ---
    {"id": "biz_man", "name": "Business Man", "desc": "3 spots Business visités", "points": 75, "icon": "business_center"},
    {"id": "tourist", "name": "Touriste", "desc": "3 spots Tourisme visités", "points": 75, "icon": "camera_alt"},
    {"id": "party_animal", "name": "Fêtard", "desc": "3 spots Nightlife visités", "points": 75, "icon": "celebration"},
    {"id": "shopper", "name": "Panier Percé", "desc": "3 spots Shopping visités", "points": 75, "icon": "shopping_bag"},
    {"id": "commuter", "name": "Voyageur", "desc": "3 spots Transport visités", "points": 75, "icon": "train"},
    {"id": "culture_fan", "name": "Intellectuel", "desc": "3 spots Culture visités", "points": 75, "icon": "school"}, # NEW
    {"id": "nature_lover", "name": "Écureuil", "desc": "3 spots Nature/Parc visités", "points": 75, "icon": "park"}, # NEW
    {"id": "market_trader", "name": "Négociant", "desc": "3 spots Marché visités", "points": 75, "icon": "storefront"}, # NEW
    {"id": "festival_goer", "name": "Festivalier", "desc": "3 spots Event visités", "points": 75, "icon": "local_activity"}, # NEW

    # --- 5. CONTEXTE (HORAIRES) (6) ---
    {"id": "early_bird", "name": "Lève-tôt", "desc": "Mendier entre 5h et 8h du matin", "points": 50, "icon": "wb_sunny"},
    {"id": "lunch_time", "name": "Pause Déj", "desc": "Mendier entre 12h et 14h", "points": 50, "icon": "restaurant"},
    {"id": "afterwork", "name": "Afterwork", "desc": "5 sessions entre 17h et 20h", "points": 60, "icon": "local_bar"}, # NEW
    {"id": "night_owl", "name": "Oiseau de Nuit", "desc": "Mendier entre 2h et 5h du matin", "points": 100, "icon": "bedtime"},
    {"id": "insomniac", "name": "Insomniaque", "desc": "5 sessions de nuit (00h-04h)", "points": 150, "icon": "nights_stay"}, # NEW
    {"id": "weekender", "name": "Du Dimanche", "desc": "Mendier un Samedi ou Dimanche", "points": 40, "icon": "weekend"},

    # --- 6. CONTRIBUTION (CRÉATION/AVIS) (6) ---
    {"id": "creator_1", "name": "Pionnier", "desc": "Créer 1 nouveau spot", "points": 100, "icon": "add_location"},
    {"id": "creator_5", "name": "Architecte", "desc": "Créer 5 spots", "points": 400, "icon": "domain"},
    {"id": "urban_planner", "name": "Urbaniste", "desc": "Créer 10 spots", "points": 800, "icon": "city"}, # NEW
    {"id": "reviewer_1", "name": "Critique", "desc": "Laisser 1 avis", "points": 30, "icon": "rate_review"},
    {"id": "reviewer_5", "name": "Influenceur", "desc": "Laisser 5 avis", "points": 150, "icon": "campaign"},
    {"id": "reviewer_20", "name": "Guide Local", "desc": "Laisser 20 avis", "points": 500, "icon": "map"}, # NEW

    # --- 7. STYLE DE JEU (STATS) (10) ---
    {"id": "loyal_5", "name": "Squatteur", "desc": "Revenir 5 fois au même spot", "points": 80, "icon": "home"},
    {"id": "loyal_10", "name": "Fidèle", "desc": "Revenir 10 fois au même spot", "points": 150, "icon": "lock"}, # NEW
    {"id": "marathon", "name": "Marathon", "desc": "Rester + de 3h d'affilée", "points": 150, "icon": "timer"},
    {"id": "camping", "name": "Camping", "desc": "Rester + de 5h d'affilée", "points": 300, "icon": "tent"}, # NEW
    {"id": "sprint", "name": "Sprint", "desc": "Rester moins de 5 min", "points": 10, "icon": "bolt"},
    {"id": "flash", "name": "Flash", "desc": "10 sessions de moins de 5 min", "points": 100, "icon": "flash_on"}, # NEW
    {"id": "rich_zone", "name": "Zone Riche", "desc": "Visiter un spot noté 5/5 en revenu", "points": 50, "icon": "attach_money"},
    {"id": "safe_zone", "name": "Zone Sûre", "desc": "Visiter un spot noté 5/5 en sécurité", "points": 50, "icon": "shield"},
    {"id": "busy_zone", "name": "Bain de foule", "desc": "Visiter un spot noté 5/5 en passage", "points": 50, "icon": "groups"},
    {"id": "star", "name": "La Star", "desc": "Visiter un spot noté >4 en Revenu ET Passage", "points": 100, "icon": "star"}, # NEW

    # --- 8. RISQUE & STRATÉGIE (7) ---
    {"id": "risk_taker", "name": "Téméraire", "desc": "Visiter un spot mal famé (Sécu < 2.5)", "points": 100, "icon": "warning"}, # NEW
    {"id": "survivor", "name": "Survivant", "desc": "5 sessions dans des spots mal famés", "points": 300, "icon": "skull"}, # NEW
    {"id": "ghost", "name": "Fantôme", "desc": "Visiter un spot désert (Passage < 1.5)", "points": 60, "icon": "visibility_off"}, # NEW
    {"id": "hermit", "name": "Ermite", "desc": "5 sessions dans des spots déserts", "points": 150, "icon": "nature_people"}, # NEW
    {"id": "gourmet", "name": "Gourmet", "desc": "5 sessions dans des spots à haut revenu (>4.5)", "points": 200, "icon": "diamond"}, # NEW
    {"id": "penny_pincher", "name": "Dèche", "desc": "5 sessions dans des spots à faible revenu (<2.0)", "points": 50, "icon": "money_off"}, # NEW
    {"id": "kamikaze", "name": "Kamikaze", "desc": "Spot bondé (>4) mais dangereux (<1.5)", "points": 500, "icon": "local_fire_department"}, # NEW
]

active_occupations: Dict[str, dict] = {}

# --- GESTION DB ---
def load_db_data():
    if not os.path.exists(DB_FILE): return {"users": [], "spots": []}
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f: return json.load(f)
    except: return {"users": [], "spots": []}

def save_db_data(data):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    if active_occupations:
        data = load_db_data()
        users = data.get("users", [])
        for spot_id, info in active_occupations.items():
            user_id = info["userId"]
            user = next((u for u in users if u["id"] == user_id), None)
            if user and "history" in user and user["history"]:
                last = user["history"][0]
                if last.get("spotId") == spot_id and not last.get("durationSeconds"):
                    start = datetime.fromisoformat(last["timestamp"])
                    last["durationSeconds"] = int((datetime.now() - start).total_seconds())
        save_db_data(data)
        active_occupations.clear()

app = FastAPI(lifespan=lifespan)

def hash_password(p: str) -> str: return hashlib.sha256(p.encode()).hexdigest()

# --- MODELS ---
class UserAuth(BaseModel):
    username: str
    password: str
    attributes: List[str] = []

class CheckInLog(BaseModel):
    spotId: str
    spotName: str
    timestamp: str
    durationSeconds: Optional[int] = 0

class User(BaseModel):
    id: str
    name: str
    password_hash: str 
    attributes: List[str] = []
    favorites: List[str] = []
    history: List[CheckInLog] = [] 
    createdAt: str
    points: int = 0
    achievements: List[str] = []

class Review(BaseModel):
    id: str
    authorName: str
    ratingRevenue: float
    ratingSecurity: float
    ratingTraffic: float
    attribute: str
    comment: str
    createdAt: str

class Spot(BaseModel):
    id: str
    name: str
    description: str
    latitude: float
    longitude: float
    category: str
    createdAt: str
    createdBy: str
    currentActiveUsers: int
    reviews: List[Review] = []
    # Helper properties for logic
    @property
    def avgRevenue(self): return sum(r.ratingRevenue for r in self.reviews)/len(self.reviews) if self.reviews else 0

class Database(BaseModel):
    users: List[User]
    spots: List[Spot]

def load_db() -> Database:
    data = load_db_data()
    for u in data.get("users", []):
        if "points" not in u: u["points"] = 0
        if "achievements" not in u: u["achievements"] = []
    return Database(**data)

def save_db(db: Database): save_db_data(db.model_dump())

# --- LOGIQUE DE DÉBLOCAGE (Mise à jour) ---
def check_new_achievements(user: User, db: Database):
    new_unlocks = []
    def has(aid): return aid in user.achievements

    # Données agrégées
    history = [h for h in user.history if h.durationSeconds and h.durationSeconds > 0]
    total_seconds = sum(h.durationSeconds for h in history)
    distinct_spots = set(h.spotId for h in history)
    
    # Données Spots créés / Avis
    created_count = sum(1 for s in db.spots if s.createdBy == user.id)
    reviews_count = sum(sum(1 for r in s.reviews if r.authorName == user.name) for s in db.spots)

    # Maps et Compteurs
    spots_map = {s.id: s for s in db.spots}
    cat_visits = {}
    spot_visits_count = {}
    
    # Compteurs contextuels
    afterwork_count = 0
    insomnia_count = 0
    high_rev_count = 0
    low_rev_count = 0
    low_sec_count = 0
    low_traf_count = 0
    flash_count = 0

    for h in history:
        s = spots_map.get(h.spotId)
        spot_visits_count[h.spotId] = spot_visits_count.get(h.spotId, 0) + 1
        
        # Check durée courte
        if h.durationSeconds < 300: flash_count += 1

        # Check horaire
        try:
            dt = datetime.fromisoformat(h.timestamp)
            if 17 <= dt.hour < 20: afterwork_count += 1
            if 0 <= dt.hour < 4: insomnia_count += 1
        except: pass

        if s:
            cat_visits.setdefault(s.category, set()).add(s.id)
            
            # Calcul moyennes spot
            if s.reviews:
                avg_rev = sum(r.ratingRevenue for r in s.reviews)/len(s.reviews)
                avg_sec = sum(r.ratingSecurity for r in s.reviews) / len(s.reviews)
                avg_traf = sum(r.ratingTraffic for r in s.reviews) / len(s.reviews)
                
                if avg_rev > 4.5: high_rev_count += 1
                if avg_rev < 2.0: low_rev_count += 1
                if avg_sec < 2.0: low_sec_count += 1
                if avg_traf < 2.0: low_traf_count += 1

    # --- CHECK DES CONDITIONS ---

    # 1. Démarrage
    if has("welcome") is False: new_unlocks.append("welcome")
    if len(history) >= 1 and not has("first_step"): new_unlocks.append("first_step")

    # 2. Temps
    if total_seconds >= 3600 and not has("time_1h"): new_unlocks.append("time_1h")
    if total_seconds >= 18000 and not has("time_5h"): new_unlocks.append("time_5h")
    if total_seconds >= 36000 and not has("time_10h"): new_unlocks.append("time_10h")
    if total_seconds >= 86400 and not has("time_24h"): new_unlocks.append("time_24h")
    if total_seconds >= 360000 and not has("time_100h"): new_unlocks.append("time_100h")

    # 3. Exploration
    if len(distinct_spots) >= 3 and not has("explorer_3"): new_unlocks.append("explorer_3")
    if len(distinct_spots) >= 10 and not has("explorer_10"): new_unlocks.append("explorer_10")
    if len(distinct_spots) >= 15 and not has("explorer_15"): new_unlocks.append("explorer_15")
    if len(distinct_spots) >= 20 and not has("explorer_20"): new_unlocks.append("explorer_20")
    
    # 4. Catégories
    all_cats = ["Tourisme", "Business", "Nightlife", "Shopping", "Transport"]
    if all(len(cat_visits.get(c, [])) >= 1 for c in all_cats) and not has("jack_of_all"): new_unlocks.append("jack_of_all")

    if len(cat_visits.get("Business", [])) >= 3 and not has("biz_man"): new_unlocks.append("biz_man")
    if len(cat_visits.get("Tourisme", [])) >= 3 and not has("tourist"): new_unlocks.append("tourist")
    if len(cat_visits.get("Nightlife", [])) >= 3 and not has("party_animal"): new_unlocks.append("party_animal")
    if len(cat_visits.get("Shopping", [])) >= 3 and not has("shopper"): new_unlocks.append("shopper")
    if len(cat_visits.get("Transport", [])) >= 3 and not has("commuter"): new_unlocks.append("commuter")
    
    if len(cat_visits.get("Culture", [])) >= 3 and not has("culture_fan"): new_unlocks.append("culture_fan")
    if len(cat_visits.get("Market", [])) >= 3 and not has("market_trader"): new_unlocks.append("market_trader")
    if len(cat_visits.get("Event", [])) >= 3 and not has("festival_goer"): new_unlocks.append("festival_goer")
    # Nature + Parc combinés
    nature_count = len(cat_visits.get("Nature", [])) + len(cat_visits.get("Parc", []))
    if nature_count >= 3 and not has("nature_lover"): new_unlocks.append("nature_lover")

    # 5. Contribution
    if created_count >= 1 and not has("creator_1"): new_unlocks.append("creator_1")
    if created_count >= 5 and not has("creator_5"): new_unlocks.append("creator_5")
    if created_count >= 10 and not has("urban_planner"): new_unlocks.append("urban_planner")
    
    if reviews_count >= 1 and not has("reviewer_1"): new_unlocks.append("reviewer_1")
    if reviews_count >= 5 and not has("reviewer_5"): new_unlocks.append("reviewer_5")
    if reviews_count >= 20 and not has("reviewer_20"): new_unlocks.append("reviewer_20")

    # 6. Fidélité / Style (Compteurs globaux)
    if any(c >= 5 for c in spot_visits_count.values()) and not has("loyal_5"): new_unlocks.append("loyal_5")
    if any(c >= 10 for c in spot_visits_count.values()) and not has("loyal_10"): new_unlocks.append("loyal_10")
    
    if flash_count >= 10 and not has("flash"): new_unlocks.append("flash")
    if afterwork_count >= 5 and not has("afterwork"): new_unlocks.append("afterwork")
    if insomnia_count >= 5 and not has("insomniac"): new_unlocks.append("insomniac")
    if high_rev_count >= 5 and not has("gourmet"): new_unlocks.append("gourmet")
    if low_rev_count >= 5 and not has("penny_pincher"): new_unlocks.append("penny_pincher")
    if low_sec_count >= 5 and not has("survivor"): new_unlocks.append("survivor")
    if low_traf_count >= 5 and not has("hermit"): new_unlocks.append("hermit")

    # 7. Contextuel (Session Actuelle - last log)
    if history:
        last = history[0] 
        # Duration
        if last.durationSeconds >= 10800 and not has("marathon"): new_unlocks.append("marathon") # 3h
        if last.durationSeconds >= 18000 and not has("camping"): new_unlocks.append("camping") # 5h
        if last.durationSeconds < 300 and not has("sprint"): new_unlocks.append("sprint") # 5 min

        # Time
        dt = datetime.fromisoformat(last.timestamp)
        if 5 <= dt.hour < 8 and not has("early_bird"): new_unlocks.append("early_bird")
        if 12 <= dt.hour < 14 and not has("lunch_time"): new_unlocks.append("lunch_time")
        if 2 <= dt.hour < 5 and not has("night_owl"): new_unlocks.append("night_owl")
        if dt.weekday() >= 5 and not has("weekender"): new_unlocks.append("weekender")

        # Spot Quality
        s = spots_map.get(last.spotId)
        if s and s.reviews:
            # Calcul stats instantané pour ce spot précis
            rev = [r.ratingRevenue for r in s.reviews]
            sec = [r.ratingSecurity for r in s.reviews]
            traf = [r.ratingTraffic for r in s.reviews]
            
            avg_rev = sum(rev)/len(rev)
            avg_sec = sum(sec)/len(sec)
            avg_traf = sum(traf)/len(traf)

            if avg_rev >= 4.8 and not has("rich_zone"): new_unlocks.append("rich_zone")
            if avg_sec >= 4.8 and not has("safe_zone"): new_unlocks.append("safe_zone")
            if avg_traf >= 4.8 and not has("busy_zone"): new_unlocks.append("busy_zone")
            
            # Badges Spéciaux uniques
            if avg_sec < 2.5 and not has("risk_taker"): new_unlocks.append("risk_taker")
            if avg_traf < 1.5 and not has("ghost"): new_unlocks.append("ghost")
            if avg_rev > 4.0 and avg_traf > 4.0 and not has("star"): new_unlocks.append("star")
            if avg_sec < 1.5 and avg_traf > 4.0 and not has("kamikaze"): new_unlocks.append("kamikaze")

    # Appliquer changements
    result = []
    for aid in new_unlocks:
        defi = next((d for d in ACHIEVEMENTS_DEF if d["id"] == aid), None)
        if defi:
            user.achievements.append(aid)
            user.points += defi["points"]
            result.append(defi)
    
    return result

# --- ROUTES ---

@app.post("/users/register", response_model=User)
def register(auth: UserAuth):
    db = load_db()
    for u in db.users:
        if u.name.lower() == auth.username.lower():
            raise HTTPException(status_code=400, detail="Pseudo déjà pris")
    
    # Welcome Achievement direct
    welcome_ach = next((a for a in ACHIEVEMENTS_DEF if a["id"] == "welcome"), None)
    points = welcome_ach["points"] if welcome_ach else 0
    achs = ["welcome"] if welcome_ach else []

    new_user = User(
        id=str(uuid4()),
        name=auth.username,
        password_hash=hash_password(auth.password),
        attributes=auth.attributes,
        favorites=[],
        history=[],
        createdAt=datetime.now().isoformat(),
        points=points,
        achievements=achs
    )
    db.users.append(new_user)
    save_db(db)
    return new_user

@app.post("/users/login", response_model=User)
def login(auth: UserAuth):
    db = load_db()
    hashed = hash_password(auth.password)
    for u in db.users:
        if u.name.lower() == auth.username.lower() and u.password_hash == hashed:
            return u
    raise HTTPException(status_code=401, detail="Identifiants incorrects")

@app.put("/users/{user_id}/attributes", response_model=User)
def update_attributes(user_id: str, attributes: List[str]):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            u.attributes = attributes
            save_db(db)
            return u
    raise HTTPException(status_code=404, detail="User not found")

@app.get("/achievements/list")
def get_achievements_list(): return ACHIEVEMENTS_DEF

@app.get("/occupations")
def get_occupations(): return active_occupations

@app.post("/spots/{spot_id}/occupy")
def occupy_spot(spot_id: str, user_id: str):
    curr = active_occupations.get(spot_id)
    if curr and curr["userId"] != user_id: raise HTTPException(409, "Occupé")
    
    db = load_db()
    user = next((u for u in db.users if u.id == user_id), None)
    spot = next((s for s in db.spots if s.id == spot_id), None)
    if not user or not spot: raise HTTPException(404, "Inconnu")

    # Auto Release others
    for s_id, info in list(active_occupations.items()):
        if info["userId"] == user_id and s_id != spot_id:
            if user.history:
                # Trouver le log ouvert correspondant
                for log in user.history:
                    if log.spotId == s_id and not log.durationSeconds:
                        st = datetime.fromisoformat(log.timestamp)
                        log.durationSeconds = int((datetime.now() - st).total_seconds())
                        break
            del active_occupations[s_id]

    active_occupations[spot_id] = {"userId": user.id, "userName": user.name}
    new_log = CheckInLog(spotId=spot.id, spotName=spot.name, timestamp=datetime.now().isoformat())
    user.history.insert(0, new_log)
    save_db(db)
    return {"status": "occupied", "history_entry": new_log}

@app.post("/spots/{spot_id}/release")
def release_spot(spot_id: str, user_id: str):
    curr = active_occupations.get(spot_id)
    if curr:
        if curr["userId"] != user_id: raise HTTPException(403, "Pas à vous")
        del active_occupations[spot_id]

    db = load_db()
    user = next((u for u in db.users if u.id == user_id), None)
    
    duration = 0
    new_badges = []

    if user and user.history:
        last = user.history[0]
        if last.spotId == spot_id and not last.durationSeconds:
            st = datetime.fromisoformat(last.timestamp)
            duration = int((datetime.now() - st).total_seconds())
            last.durationSeconds = duration
            
            # Check Badges
            new_badges = check_new_achievements(user, db)
            save_db(db)

    return {"status": "released", "duration": duration, "new_achievements": new_badges, "total_points": user.points if user else 0}

@app.get("/users/top")
def get_top_users(period: str = "forever", sort_by: str = "time"):
    db = load_db()
    
    if sort_by == "points":
        lb = [{"userId": u.id, "name": u.name, "score": u.points, "attributes": u.attributes} for u in db.users if u.points > 0]
        lb.sort(key=lambda x: x["score"], reverse=True)
        return lb[:50]

    now = datetime.now()
    cutoff = None
    if period == "daily": cutoff = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "weekly": cutoff = now - timedelta(days=7)
    elif period == "monthly": cutoff = now - timedelta(days=30)

    lb = []
    for user in db.users:
        secs = 0
        for log in user.history:
            if log.durationSeconds:
                if cutoff is None or datetime.fromisoformat(log.timestamp) >= cutoff:
                    secs += log.durationSeconds
        if secs > 0:
            lb.append({"userId": user.id, "name": user.name, "score": secs, "attributes": user.attributes})
    
    lb.sort(key=lambda x: x["score"], reverse=True)
    return lb[:50]

@app.post("/users/{user_id}/favorites/{spot_id}")
def add_favorite(user_id: str, spot_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            if spot_id not in u.favorites:
                u.favorites.append(spot_id)
                save_db(db)
            return {"status": "ok"}
    raise HTTPException(404)

@app.delete("/users/{user_id}/favorites/{spot_id}")
def remove_favorite(user_id: str, spot_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            if spot_id in u.favorites:
                u.favorites.remove(spot_id)
                save_db(db)
            return {"status": "ok"}
    raise HTTPException(404)

@app.get("/users/{user_id}/favorites", response_model=List[str])
def get_favorites(user_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id: return u.favorites
    raise HTTPException(404)

@app.get("/spots", response_model=List[Spot])
def get_spots(): return load_db().spots

@app.post("/spots", response_model=Spot)
def create_spot(spot: Spot):
    db = load_db()
    if not spot.id: spot.id = str(uuid4())
    db.spots.append(spot)
    save_db(db)
    return spot

@app.post("/spots/{spot_id}/reviews", response_model=Review)
def add_review(spot_id: str, review: Review):
    db = load_db()
    for s in db.spots:
        if s.id == spot_id:
            s.reviews.insert(0, review)
            save_db(db)
            return review
    raise HTTPException(404)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)