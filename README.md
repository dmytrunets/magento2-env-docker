# magento2-docker-dev
1. Open docker-compose.yml 
1. Replace %project_name% and with your one
1. Replace %project_global_path% with global path to your project (e. g. `/var/www/my-project`)
1. Add `magento2.local` to your `hosts` file or replace this hostname with desired one in all the env files
1. Put your auth keys into `build/php/auth.json` (you can skip this step if your project has this file in the root folder)
1. Run `docker-compose up`
1. Wait until all the stages inside PHP-container will be done
1. Now you can press `Ctrl+C` and run it in the background`docker compose up -d`
