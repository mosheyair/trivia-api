file.ps1 is make the connection between program to the server
deploy.ps1 - הינו סקריפט פריסה לשרת.
“סקריפט פריסה לשרת”
זה קובץ פקודות שמריץ רצף אוטומטי של צעדים שכל פעם עושים ידנית:
בניית הפרויקט (Maven)
יצירת JAR
העתקה לשרת (SCP)
הפעלה/אתחול התהליך על השרת (למשל דרך pm2)
בדיקות מהירות (בריאות/לוג)
מטרה: לחיצה אחת → גרסה חדשה רצה בשרת.

במקרה הזה השתמשנו בסקריפט שכתוב בשפת POWER PowerShell
יש עוד מספר אפשרויות לכתיבת סקריפט פריסה מול השרת:
    1. PowerShell Script
    2. Bash/WSL
    3. WinSCP / GUI
    4. GitHub Actions
    5. Pull-based
    6. rsync
    7. Docker/Compose

     1 - PowerShell
ps = PowerShell script

       שלד טיפוסי של PowerShell
 #עוצרים על כל שגיאה
$ErrorActionPreference = 'Stop'

# 1) פרמטרים/משתנים לפרויקט
$projectRoot = Split-Path -Parent $PSCommandPath    # תקיית הקובץ
$jarName     = "app.jar"                             # השם שנוצר ב-target
$remoteUser  = "moka"
$remoteHost  = "srv787122.hostinger"                 # דוגמה
$remotePath  = "/home/moka/api"                      # איפה שמים את ה-JAR
$pm2Name     = "spring-api"                          # שם התהליך ב-pm2

# 2) בנייה מקומית עם Maven Wrapper (Windows)
Write-Host "==> Building with Maven Wrapper..."
Push-Location $projectRoot
.\mvnw.cmd clean package -DskipTests
Pop-Location

# 3) העתקת ה-JAR לשרת (SCP של Windows OpenSSH)
Write-Host "==> Copying JAR to server..."
scp "$projectRoot\target\$jarName" "$remoteUser@$remoteHost:$remotePath/$jarName"

# 4) אתחול האפליקציה בשרת (SSH+pm2)
Write-Host "==> Restarting PM2 on server..."
ssh "$remoteUser@$remoteHost" `
  "pm2 start 'java -jar $remotePath/$jarName --spring.profiles.active=prod --spring.config.additional-location=$remotePath/' --name $pm2Name --update-env || pm2 restart $pm2Name --update-env"

# 5) בדיקת מצב מהירה (אופציונלי)
Write-Host "==> PM2 status:"
ssh "$remoteUser@$remoteHost" "pm2 status $pm2Name"
Write-Host "✅ Deploy finished."

           הסבר שורה שורה לקוד
 $ErrorActionPreference = 'Stop' — כל שגיאה מפילה את הסקריפט (כדי שלא תמשיך לפרוס חצי־דרך).
 בלוק ה־משתנים: מרכז במקום אחד נתיבים/שמות כדי שלא יתפזרו בקוד.
 .\mvnw.cmd clean package -DskipTests — בנייה מקומית עם Maven Wrapper (בווינדוס).
 clean מנקה target.
 package יוצר JAR בתוך target.
 -DskipTests מאיץ כשלא צריך להריץ טסטים.
 scp — מעביר את ה־JAR לשרת לנתיב $remotePath.
 ssh ... pm2 ... — מפעיל או עושה restart ל־PM2 על השרת עם הפקודה של Spring Boot (כולל --spring.profiles.active=prod ו־--spring.config.additional-location כדי שייקרא קובץ properties מהנתיב).
 pm2 status — נותן אינדיקציה מהירה שהאפליקציה אכן רצה.
 הערה: אם אין לך scp/ssh בסביבת Windows, ודא שהרכיב OpenSSH Client מותקן (ב־“Optional features”). לחלופין אפשר להשתמש ב־PuTTY (pscp, plink).

          2 - Bash/WSL
 if we have WSL is natural to write script deploy.sh
                  שלד למקרה הזה
 #!/usr/bin/env bash
 set -e
 SERVER="mokafullstack@69.62.109.118"
 REMOTE="/home/moka/api"
 PROFILE="prod"

 ./mvnw -DskipTests package
 JAR=$(ls -t target/*.jar | head -n1)

 scp "$JAR" "$SERVER:$REMOTE/app.new.jar"
 ssh "$SERVER" "mv $REMOTE/app.new.jar $REMOTE/app.jar && \
 (pm2 restart spring-api || pm2 start 'java -jar $REMOTE/app.jar --spring.profiles.active=$PROFILE --spring.config.additional-location=$REMOTE/' --name spring-api) && pm2 save"

הרצה : bash deploy.ssh מ wsl ubuntu
יתרונות: תחביר פופולרי רץ אותו דבר בלינוקס ושרת
חסרונות: צריך לעבוד מחלון WSL

             WinSCP / GUI “גרירה ושחרור”
open WinSCP connection with SFTP to the server
drag (גרור) the JAR to home/mokafullstack/api/ with name app.new.jar
push "open in PuTTY / open terminal" → run Commands

   Exampel code
mv /home/moka/api/app.new.jar /home/moka/api/app.jar
pm2 restart spring-api || pm2 start "java -jar /home/moka/api/app.jar --spring.profiles.active=prod --spring.config.additional-location=/home/moka/api/" --name spring-api
pm2 save

* יתרונות : בלי סקריפטים
*    חסרונות : ידני פחות אוטומציה

           GitHub Actions
push to MAIN ⇒ build JAR ⇒ deploy (פריסה) at SSH

             Exampel code (.github/workflows/deploy.yml)
name: Build & Deploy
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '21' }
      - run: ./mvnw -DskipTests package
      - name: Copy & Restart via SSH
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          source: "target/*.jar"
          target: "/home/moka/api/app.new.jar"
      - uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            mv /home/moka/api/app.new.jar /home/moka/api/app.jar
            pm2 restart spring-api || pm2 start "java -jar /home/moka/api/app.jar --spring.profiles.active=prod --spring.config.additional-location=/home/moka/api/" --name spring-api
            pm2 save

יתרונות : אוטומטי עקיב
חסרונות : דורש הגדרה חד פעמית של Secrets


                pull - based (עבודה בתוך השרת)
בשרת יש  (clone ( של הריפו)

ssh mokafullstack@... << 'EOF'
  cd /home/moka/app
  git pull
  ./mvnw -DskipTests package
  cp target/*.jar /home/moka/api/app.jar
  pm2 restart spring-api || pm2 start "java -jar /home/moka/api/app.jar --spring.profiles.active=prod --spring.config.additional-location=/home/moka/api/" --name spring-api
  pm2 save
EOF

יתרונות : הכל מתרחש בשרת
need JDK/maven at the server (or Maven Wrapper)  חסרונות :

                   rsync
           יעיל לגרסאות/ קבצים רבים
מחליף את SCP

 rsync -avz target/app.jar mokafullstack@IP:/home/moka/api/app.new.jar

ואז SSH כמו קודם

             Docker/Compose

לבנות תמונה בCI לדחוף לREGISTRY והשרת מושך ומריץ:
docker compose up -d

