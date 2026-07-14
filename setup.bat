@echo off
echo ===== INKWELL KURULUM =====
echo.

echo [1/2] Flutter bagimliliklar yukleniyor...
cd /d "%~dp0internship2project"
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo HATA: flutter pub get basarisiz oldu!
    pause
    exit /b 1
)
echo Flutter bagimliliklar OK!
echo.

echo [2/2] Python (backend) bagimliliklar yukleniyor...
cd /d "%~dp0internship2project\backend"
pip install -r requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo HATA: pip install basarisiz oldu!
    pause
    exit /b 1
)
echo Python bagimliliklar OK!
echo.

echo ===== KURULUM TAMAMLANDI =====
echo.
echo Backend'i baslatmak icin:
echo   cd internship2project\backend
echo   uvicorn main:app --reload
echo.
echo Flutter'i baslatmak icin:
echo   cd internship2project
echo   flutter run
echo.
pause
