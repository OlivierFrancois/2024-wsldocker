#!/bin/bash

# Vérifier si le conteneur est déjà en cours d'exécution et le lance si non
if [ ! "$(docker ps -q -f name=apache_php82)" ]; then
    docker-compose up -d
fi

# Définition de la structure de données
projects=("bbapp:project_name:bbapp:document_root:bbapp/public:project_path:./../www/2023-bbapp"
  "adoxia_v3:project_name:adoxia_v3:document_root:adoxia_v3/public:project_path:./../www/adoxia_v3")

# Boucle pour parcourir chaque projet
for project in "${projects[@]}"; do
    IFS=':' read -r -a project_info <<< "$project"
    project_name="${project_info[2]}"
    document_root="${project_info[4]}"
    project_path="${project_info[6]}"
    echo "DEBUT DE $project_name"

    # Créer le .conf
    docker exec apache_php82-webserver cp "/etc/apache2/sites-available/template.conf" "/etc/apache2/sites-available/${project_name}.conf"
    # Compléter le fichier .conf
    docker exec apache_php82-webserver sed -i "s@__document_root__@$(printf '%q' "${document_root}")@g" "/etc/apache2/sites-available/$(printf '%q' "${project_name}").conf"


    # Activer le site
    docker exec apache_php82-webserver a2ensite "${project_name}.conf"

    # Créer le .conf
    docker exec apache_php82-webserver cp "/etc/apache2/sites-available/template-ssl.conf" "/etc/apache2/sites-available/${project_name}-ssl.conf"
    # Compléter le fichier .conf
    docker exec apache_php82-webserver sed -i "s@__document_root__@$(printf '%q' "${document_root}")@g" "/etc/apache2/sites-available/$(printf '%q' "${project_name}")-ssl.conf"
    docker exec apache_php82-webserver sed -i "s/__domain__/${project_name}/g" "/etc/apache2/sites-available/${project_name}-ssl.conf"
    # Activer le site
    docker exec apache_php82-webserver a2ensite "${project_name}-ssl.conf"

#    if ! grep -q "${project_name}.docker" /etc/hosts; then
#        # Ajouter une entrée dans /etc/hosts pour le vhost du projet sur le Mac
#        echo "127.0.0.1    ${project_name}.docker" | sudo tee -a /etc/hosts > /dev/null
#    fi
done

docker exec apache_php82-webserver service apache2 reload