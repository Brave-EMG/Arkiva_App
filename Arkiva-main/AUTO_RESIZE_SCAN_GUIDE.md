# Guide du Redimensionnement Automatique - Scan ARKIVA

## 🎯 Fonctionnalité

Le redimensionnement automatique du scan permet à l'application de détecter automatiquement les bords d'un document et d'ajuster le cadre de capture pour optimiser la qualité du scan.

## ✨ Fonctionnalités Principales

### 🔍 **Détection Automatique des Bords**
- Analyse en temps réel de l'image de la caméra
- Détection des contours du document
- Calcul de la confiance de détection
- Ajustement progressif du cadre

### 📐 **Redimensionnement Intelligent**
- Adaptation selon l'orientation (portrait/paysage)
- Respect des proportions du document
- Validation des dimensions optimales
- Animation fluide des transitions

### ⚙️ **Paramètres Configurables**
- **Sensibilité** : Ajuste la précision de détection
- **Intervalle** : Fréquence de mise à jour (ms)
- **Seuil de confiance** : Niveau minimum pour appliquer les changements
- **Ajustement maximum** : Limite les changements de taille

## 🎮 Contrôles Utilisateur

### **Boutons de l'Interface**

1. **🔦 Flash** (en haut à droite)
   - Active/désactive le flash
   - Améliore la détection en faible luminosité

2. **🎯 Auto-resize** (en haut à droite)
   - Active/désactive la détection automatique
   - Indicateur vert = activé, gris = désactivé

3. **⚙️ Paramètres** (en haut à droite)
   - Affiche les paramètres de détection
   - Permet de voir les valeurs actuelles

4. **📷 Capture** (centre)
   - Bouton principal de capture
   - Désactivé pendant le traitement

5. **🔄 Reset** (en bas à droite)
   - Réinitialise le cadre aux dimensions par défaut
   - Efface l'historique des détections

## 🔧 Fonctionnement Technique

### **Processus de Détection**

1. **Initialisation**
   ```
   Caméra → Permissions → Détection périodique
   ```

2. **Analyse Continue**
   ```
   Capture image → Détection bords → Calcul dimensions → Validation → Application
   ```

3. **Validation**
   ```
   Confiance > seuil → Image stable → Dimensions valides → Animation
   ```

### **Algorithme de Redimensionnement**

```dart
// 1. Détection des bords
final edges = await EdgeDetectionService.detectDocumentEdges(imageFile);

// 2. Calcul des dimensions optimales
final optimalFrame = EdgeDetectionService.calculateOptimalFrame(
  edges, screenSize, isLandscape
);

// 3. Validation
if (EdgeDetectionService.isValidFrame(optimalFrame)) {
  // 4. Application avec animation
  _applyFrameWithAnimation(optimalFrame);
}
```

## 📱 Adaptations par Appareil

### **Mobile (Portrait)**
- Largeur : 85% de l'écran
- Hauteur : 70% de la largeur
- Position : Centré avec marges

### **Tablette (Paysage)**
- Largeur : 60% de l'écran
- Hauteur : 80% de la largeur
- Position : Ajustée pour l'orientation

### **Desktop**
- Largeur : 70% de l'écran
- Hauteur : 75% de la largeur
- Position : Optimisée pour grand écran

## 🎨 Indicateurs Visuels

### **Cadre de Capture**
- **Blanc** : Mode normal
- **Bleu** : Détection en cours
- **Points bleus** : Indicateurs de détection

### **Compteur de Détections**
- Affiche le nombre de détections récentes
- Aide à évaluer la stabilité de l'image

### **Messages de Confirmation**
- "Cadre ajusté automatiquement (confiance: XX%)"
- "Cadre réinitialisé"
- "Détection automatique des bords..."

## ⚡ Optimisations de Performance

### **Gestion de la Mémoire**
- Limitation à 5 détections récentes
- Nettoyage automatique des images temporaires
- Arrêt de la détection pendant la capture

### **Optimisation CPU**
- Détection périodique (pas en continu)
- Validation avant application
- Animation fluide avec `Curves.easeInOut`

### **Adaptation aux Conditions**
- Sensibilité ajustée selon la luminosité
- Intervalle adapté au mouvement
- Seuils dynamiques selon les conditions

## 🐛 Dépannage

### **Problèmes Courants**

1. **Détection instable**
   - Vérifiez l'éclairage
   - Stabilisez l'appareil
   - Ajustez la sensibilité

2. **Cadre trop petit/grand**
   - Utilisez le bouton Reset
   - Vérifiez la distance du document
   - Ajustez les paramètres

3. **Performance lente**
   - Désactivez temporairement l'auto-resize
   - Augmentez l'intervalle de détection
   - Fermez les autres applications

### **Solutions**

```dart
// Réinitialiser les paramètres
_detectionParams = EdgeDetectionService.optimizeDetectionParameters(
  lightLevel, motionLevel, isLandscape
);

// Forcer une détection
_performEdgeDetection();

// Valider manuellement
if (EdgeDetectionService.isValidFrame(currentFrame)) {
  _applyFrame(currentFrame);
}
```

## 📊 Métriques de Qualité

### **Indicateurs de Performance**
- **Taux de détection** : % de captures réussies
- **Temps de réponse** : Délai d'ajustement
- **Précision** : Correspondance avec le document
- **Stabilité** : Variance des détections

### **Seuils Recommandés**
- **Confiance minimale** : 70%
- **Intervalle optimal** : 1000ms
- **Sensibilité par défaut** : 0.7
- **Ajustement max** : 20%

## 🔮 Améliorations Futures

### **Fonctionnalités Prévues**
- [ ] Détection multi-documents
- [ ] Reconnaissance de type de document
- [ ] Correction automatique de perspective
- [ ] Sauvegarde des paramètres utilisateur

### **Optimisations Techniques**
- [ ] Utilisation d'OpenCV pour la détection
- [ ] Machine Learning pour l'amélioration
- [ ] Support GPU pour les calculs
- [ ] Cache des détections récentes

## 📝 Notes de Développement

### **Architecture**
```
ScanScreen
├── EdgeDetectionService
├── ResponsiveService
├── ImageProcessingService
└── AnimationController
```

### **Dépendances**
- `camera` : Accès à la caméra
- `permission_handler` : Gestion des permissions
- `dart:async` : Timers et async/await
- `dart:math` : Calculs mathématiques

### **Tests Recommandés**
- [ ] Test sur différents appareils
- [ ] Test en conditions de faible luminosité
- [ ] Test avec différents types de documents
- [ ] Test de performance sous charge

---

**Version** : 1.0.0  
**Dernière mise à jour** : $(date)  
**Auteur** : Équipe ARKIVA 