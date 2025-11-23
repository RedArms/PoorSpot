import json
import os
import random
from datetime import datetime, timedelta
from main import load_db, save_db, check_new_achievements, CheckInLog

# Configuration
MIN_DURATION_MINUTES = 15
MAX_DURATION_MINUTES = 240 # 4 heures

def populate_recent_activity(db):
    print("\n--- ÉTAPE 1 : SIMULATION D'ACTIVITÉ RÉCENTE (24h/7j/30j) ---")
    logs_created = 0
    now = datetime.now()
    spots = db.spots

    if not spots:
        print("Aucun spot disponible pour générer de l'activité.")
        return False

    # On mélange les utilisateurs pour ne pas que ce soit toujours les mêmes en tête
    shuffled_users = list(db.users)
    random.shuffle(shuffled_users)

    for user in shuffled_users:
        # PROBABILITÉS D'ACTIVITÉ
        # 50% de chance d'être actif aujourd'hui (24h)
        is_active_daily = random.random() < 0.5 
        # 70% de chance d'être actif cette semaine (7j)
        is_active_weekly = random.random() < 0.7
        # 90% de chance d'être actif ce mois-ci (30j)
        is_active_monthly = random.random() < 0.9

        # --- GÉNÉRATION 24H ---
        if is_active_daily:
            # 1 session dans les dernières 24h
            spot = random.choice(spots)
            duration = random.randint(MIN_DURATION_MINUTES * 60, 120 * 60) # Sessions plus courtes le jour même
            start_time = now - timedelta(hours=random.randint(0, 23), minutes=random.randint(0, 59))
            
            new_log = CheckInLog(spotId=spot.id, spotName=spot.name, timestamp=start_time.isoformat(), durationSeconds=duration)
            user.history.append(new_log)
            logs_created += 1

        # --- GÉNÉRATION SEMAINE (1 à 6 jours en arrière) ---
        if is_active_weekly:
            nb_sessions = random.randint(1, 3)
            for _ in range(nb_sessions):
                spot = random.choice(spots)
                duration = random.randint(MIN_DURATION_MINUTES * 60, MAX_DURATION_MINUTES * 60)
                start_time = now - timedelta(days=random.randint(1, 6), hours=random.randint(0, 23))
                
                new_log = CheckInLog(spotId=spot.id, spotName=spot.name, timestamp=start_time.isoformat(), durationSeconds=duration)
                user.history.append(new_log)
                logs_created += 1

        # --- GÉNÉRATION MOIS (7 à 29 jours en arrière) ---
        if is_active_monthly:
            nb_sessions = random.randint(2, 5)
            for _ in range(nb_sessions):
                spot = random.choice(spots)
                duration = random.randint(MIN_DURATION_MINUTES * 60, MAX_DURATION_MINUTES * 60)
                start_time = now - timedelta(days=random.randint(7, 29), hours=random.randint(0, 23))
                
                new_log = CheckInLog(spotId=spot.id, spotName=spot.name, timestamp=start_time.isoformat(), durationSeconds=duration)
                user.history.append(new_log)
                logs_created += 1

    print(f"Terminé : {logs_created} fausses sessions récentes générées pour remplir les graphiques.")
    return logs_created > 0

def fix_history_from_reviews(db):
    print("\n--- ÉTAPE 2 : COHÉRENCE AVIS <-> HISTORIQUE ---")
    logs_created = 0
    
    for spot in db.spots:
        for review in spot.reviews:
            user = next((u for u in db.users if u.name == review.authorName), None)
            if user:
                review_date = datetime.fromisoformat(review.createdAt)
                has_history = False
                
                # Check doublons larges
                for h in user.history:
                    if h.spotId == spot.id:
                        try:
                            h_date = datetime.fromisoformat(h.timestamp)
                            # Si session existante proche de l'avis, on ne touche pas
                            if abs((h_date - review_date).total_seconds()) < 86400 * 2: 
                                has_history = True
                                if not h.durationSeconds: h.durationSeconds = random.randint(1800, 7200)
                                break
                        except: pass
                
                if not has_history:
                    duration = random.randint(1800, 10800) # 30min à 3h
                    start_time = review_date - timedelta(seconds=duration + 300)
                    user.history.append(CheckInLog(spotId=spot.id, spotName=spot.name, timestamp=start_time.isoformat(), durationSeconds=duration))
                    logs_created += 1

    print(f"Terminé : {logs_created} sessions historiques restaurées depuis les avis.")
    return logs_created > 0

def cleanup_and_sort(db):
    print("\n--- ÉTAPE 3 : NETTOYAGE & TRI ---")
    users_fixed = 0
    for user in db.users:
        if user.history:
            # Tri du plus récent au plus vieux
            user.history.sort(key=lambda x: datetime.fromisoformat(x.timestamp), reverse=True)
            
            # Correction Date de création
            oldest_log = user.history[-1]
            try:
                created_at = datetime.fromisoformat(user.createdAt)
                first_visit = datetime.fromisoformat(oldest_log.timestamp)
                if first_visit < created_at:
                    new_date = first_visit - timedelta(days=random.randint(1, 5))
                    user.createdAt = new_date.isoformat()
                    users_fixed += 1
            except: pass
    print(f"Dates corrigées pour {users_fixed} utilisateurs.")

def sync_all_users():
    print("=== DÉMARRAGE DE LA GÉNÉRATION DE DONNÉES ===")
    try:
        db = load_db()
    except Exception as e:
        print(f"Erreur : {e}")
        return

    # 1. Remplir les périodes récentes (24h, 7j, 30j) pour les graphiques
    changed_1 = populate_recent_activity(db)
    
    # 2. Assurer que les avis ont une session associée
    changed_2 = fix_history_from_reviews(db)
    
    # 3. Trier et réparer les dates
    cleanup_and_sort(db)

    # 4. Recalculer les succès (Points & Badges)
    print("\n--- ÉTAPE 4 : CALCUL DES SCORES & SUCCÈS ---")
    users_updated = 0
    for user in db.users:
        # Reset des points pour recalculer propre
        # user.points = 0 
        # user.achievements = [] 
        # (Optionnel : Décommenter ci-dessus si tu veux un reset total des scores, 
        # sinon on ajoute juste ce qui manque)
        
        start_pts = user.points
        check_new_achievements(user, db)
        if user.points != start_pts:
            users_updated += 1
            # print(f"  -> {user.name} : {user.points} pts")

    if changed_1 or changed_2 or users_updated > 0:
        save_db(db)
        print("\n✅ SUCCÈS : Base de données mise à jour et sauvegardée !")
        print("Les classements 24h, 7 jours et 30 jours devraient maintenant être cohérents.")
    else:
        print("\nAucun changement nécessaire.")

if __name__ == "__main__":
    if not os.path.exists("db.json"):
        print("Erreur: db.json introuvable.")
    else:
        sync_all_users()