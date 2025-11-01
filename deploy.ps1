# קובץ עם סיומת ps1 שהיא קיצור לPowerShell script
#  הסקריפט נכתב בפורמט PowerShell ומבוצע ע״י PowerShell.


# הגדרות

$server  = root@69.62.109.118 # המשתמש + כתובת ה־IP של השרת
$remote  = "/home/moka/api" # הנתיב בשרת שבו יושב הקובץ JAR וקובץ ההגדרות
$profile = "prod" # פרופיל Spring Boot שנטען (כאן "prod" – הפקה).

#  בניה של JAR

Write-Host ">> Building JAR (skip tests)..." -ForegroundColor Cyan # מדפיס הודעה צבעונית לטרמינל
mvn -DskipTests package #  בונה את הפרויקט ע"י Maven (מדלג על טסטים), ויוצר JAR בתיקיית target.
if ($LASTEXITCODE -ne 0) { throw "Maven build failed" } #  אם Maven נכשל → זורק שגיאה ומפסיק את הסקריפט.

#  חיפוש הקובץ JAR האחרון שנוצר
#  מחפש את ה־JAR הכי חדש בתיקיית target
#  אם לא נמצא JAR → זורק שגיאה
#  מדפיס מהו הקובץ שנמצא

$jar = Get-ChildItem -Path "target" -Filter "*.jar" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $jar) { throw "JAR not found under target/" }
Write-Host ">> JAR: $($jar.FullName)" -ForegroundColor Green

# העלאה לשרת בשם זמני (app.new.jar) קודם מעבירים ואחר כך מחליפים

Write-Host ">> Uploading to server..." -ForegroundColor Cyan #  מדפיס הודעה צבעונית לטרמינל
scp "$($jar.FullName)" "${server}:${remote}/app.new.jar" #SCP:  app.new.jar שולח את קובץ הג'אר לשרת בשם

#  החלפה + הפעלה מחדש בשרת

$cmd = @"
mv $remote/app.new.jar $remote/app.jar && \
(pm2 restart spring-api || pm2 start "java -jar $remote/app.jar --spring.profiles.active=$profile --spring.config.additional-location=$remote/" --name spring-api) && \
pm2 save
"@
   #  mv: מחליף את app.new.jar with app.jar
   # pm2 restart spring-api: מנסה לעשות איתחול
   # pm2 start... : אים לא קיים יפעיל - שגיאה - יפעיל מחדש את האפליקציה
   # pm2 save: שומר את המצב כדי שהאפליקציה תעלה אוטומטית אחרי ריסט
   #  כל מה שבתוך ה־@" ... "@ נכנס לתוך משתנה $cmd כטקסט — ואח"כ נשלח ל־SSH לביצוע בשרת.

#הפעלת הפקודה ב־SSH

Write-Host ">> Restarting PM2 on server..." -ForegroundColor Cyan  # מדפיס הודעה צבעונית לטרמינל
ssh $server $cmd  # מתחבר לשרת ומריץ את הפקודות מהבלוק הקודם (mv, pm2, וכו').

Write-Host ">> Done. API should be live on port 8081 (via reverse proxy)." -ForegroundColor Green #  מדפיס הודעה צבעונית לטרמינל

 #                 pm2
 #           pm = process manager
 #        זה מנהל תהליכים לאפליקציות שרצות לאורך זמן ותפקידו:
 #         להריץ תהליכים
 #        (אם נופל להרים שוב)לפקח עליהם
 #        לשמור הגדרות
 #        להפעיל מחדש אחרי ריסטארט
 #          להציג לוגים

 #                pm2 restart spring-api || pm2 start "java -jar $remote/app.jar --spring.profiles.active=$profile
 #               spring.config.additional-location=$remote/" name spring-api) && \
 #                pm2 save
#מפעיל אפליקציית Java (בקובץ app.jar) בתור תהליך חדש, ומפקח עליו
# java -jar: פקודת ג'אווה רגילה שמריצה את האפליקציה
# pm2 start:  עוטף אותה כדי שתישאר בחיים ותנוטר.

#pm2 start
#"java -jar /home/moka/api/app.jar"
#--spring.profiles.active=prod
#--spring.config.additional-location=/home/moka/api/: מוסיף לספרינג עוד תיקיה שבה יחפש את קובץ ההגדרות
#
#
#
#