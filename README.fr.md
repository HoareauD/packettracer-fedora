# Packet Tracer sur Fedora

[English](README.md)

Installateur communautaire pour Fedora x86_64 avec DNF. Le lancement sur Fedora 45 avec le paquet Cisco reste à valider.

Téléchargez le fichier `.deb` Ubuntu 64 bits depuis [Cisco Networking Academy](https://www.netacad.com/resources/lab-downloads). Consultez les conditions de licence de Cisco avant d’utiliser le logiciel. La licence MIT couvre les scripts et la documentation de ce dépôt. Packet Tracer est disponible séparément auprès de Cisco.

```bash
git clone https://github.com/HoareauD/packettracer-fedora.git
cd packettracer-fedora
bash install.sh "$HOME/Téléchargements/CiscoPacketTracer.deb"
bash doctor.sh
bash update.sh /chemin/vers/CiscoPacketTracer_nouveau.deb
bash uninstall.sh
```

Vous pouvez laisser le fichier `.deb` dans votre dossier Téléchargements. Remplacez `CiscoPacketTracer.deb` par le nom exact du fichier téléchargé. Si votre dossier s’appelle `Downloads`, utilisez `$HOME/Downloads` à la place de `$HOME/Téléchargements`. Lancez les scripts depuis votre compte utilisateur. DNF peut demander les droits d’administration pour installer les dépendances manquantes. Le script extrait le dossier `opt/pt` et ajoute une entrée au menu GNOME ou KDE. Sous Wayland, il utilise Qt avec XCB via XWayland par défaut. Pour diagnostiquer le chargement des modules Qt, lancez `bash doctor.sh --qt-debug`.

La mise à jour conserve les anciennes versions pour les processus en cours. La désinstallation retire les versions gérées et le lanceur. Les paquets DNF et vos fichiers personnels restent disponibles.
