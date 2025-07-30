# 🔧 Guide de Résolution - Connexion Mobile ARKIVA

## ❌ **Problème Identifié**

### **Erreur de Connexion**
```
ClientException: Broken pipe, uri=http://localhost:3000/api/auth/login
```

**Cause** : L'application mobile essaie de se connecter au backend sur `localhost:3000`, mais :
- Sur mobile, `localhost` ne fonctionne pas
- Le backend n'est peut-être pas démarré
- L'IP de connexion n'est pas correcte

## ✅ **Solutions**

### **1. Démarrer le Backend**

```bash
# Aller dans le dossier backend
cd Arkiva-main/backend

# Installer les dépendances
npm install

# Démarrer le serveur
npm start
```

**Vérification** : Le serveur doit afficher :
```
🚀 Server is running at: http://0.0.0.0:3000
```

### **2. Configuration API Mobile**

#### **Pour Émulateur Android**
```dart
return 'http://10.0.2.2:3000';
```

#### **Pour Appareil Physique**
```dart
return 'http://VOTRE_IP_LOCALE:3000';
```

**Trouver votre IP locale** :
```bash
# Sur Linux/Mac
ifconfig

# Sur Windows
ipconfig
```

### **3. Vérifier la Connexion**

#### **Test du Backend**
```bash
curl http://localhost:3000
```
**Résultat attendu** :
```json
{"message": "Welcome to Arkiva Platform API"}
```

#### **Test depuis Mobile**
1. Ouvrir l'application
2. Essayer de se connecter
3. Vérifier les logs pour les erreurs

## 🔧 **Configuration Détaillée**

### **1. Fichier de Configuration**
Le fichier `lib/config/api_config.dart` a été mis à jour :

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else {
    // Pour émulateur Android
    return 'http://10.0.2.2:3000';
    
    // Pour appareil physique (remplacer par votre IP)
    // return 'http://192.168.1.147:3000';
  }
}
```

### **2. Variables d'Environnement Backend**
Vérifier le fichier `.env` dans le dossier backend :

```env
PORT=3000
DB_HOST=localhost
DB_USER=your_username
DB_PASS=your_password
DB_NAME=arkiva_db
```

## 📱 **Tests par Plateforme**

### **Web**
- ✅ Utilise `localhost:3000`
- ✅ Fonctionne directement

### **Émulateur Android**
- ✅ Utilise `10.0.2.2:3000`
- ✅ Connexion automatique

### **Appareil Physique**
- ⚠️ Nécessite l'IP locale de votre machine
- ⚠️ Même réseau WiFi requis

## 🐛 **Dépannage**

### **Problème 1 : Backend ne démarre pas**
```bash
# Vérifier les dépendances
npm install

# Vérifier les logs
npm start

# Vérifier le port
netstat -tulpn | grep 3000
```

### **Problème 2 : Connexion refusée**
```bash
# Vérifier le firewall
sudo ufw status

# Autoriser le port 3000
sudo ufw allow 3000
```

### **Problème 3 : IP incorrecte**
```bash
# Trouver votre IP
hostname -I

# Tester la connexion
ping VOTRE_IP
```

### **Problème 4 : CORS**
Ajouter dans le backend (`app.js`) :
```javascript
app.use(cors({
  origin: ['http://localhost:3000', 'http://10.0.2.2:3000'],
  credentials: true
}));
```

## 📊 **Vérification**

### **Checklist de Connexion**
- [ ] Backend démarré sur le port 3000
- [ ] Configuration API correcte
- [ ] Même réseau WiFi (appareil physique)
- [ ] Pas de firewall bloquant
- [ ] Base de données accessible

### **Test de Connexion**
1. **Backend** : `curl http://localhost:3000`
2. **Mobile** : Essayer de se connecter
3. **Logs** : Vérifier les erreurs dans la console

## 🚀 **Prochaines Étapes**

### **Pour le Développement**
1. **Backend** : Toujours démarré pendant les tests
2. **Configuration** : Adapter l'IP selon l'environnement
3. **Logs** : Surveiller les erreurs de connexion

### **Pour la Production**
1. **Serveur** : Configuration de production
2. **SSL** : Certificats HTTPS
3. **Load Balancer** : Distribution de charge

---

**✅ Une fois ces étapes suivies, l'application mobile devrait pouvoir se connecter au backend sans erreur !** 