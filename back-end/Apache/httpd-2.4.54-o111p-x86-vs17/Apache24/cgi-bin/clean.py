#!C:/Users/caobo3/AppData/Local/Programs/Python/Python38/python.exe
import shutil
import os

shutil.rmtree('D:/tools/windows/ftpPath/src')  
os.mkdir('D:/tools/windows/ftpPath/src')  

print('Content-Type: text/plain')
print('')
print('[cgi-clean]  Previous source images has been cleaned.')