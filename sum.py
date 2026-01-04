f = 9
coa = 10
oop = 10 
cs = 9 
se = 9 
fm = 9 
u = 10

a = (f*4 + coa*4 + oop*4 + cs*4 + se*4+ fm*4 + u*2)/26
b = 10
x = 336.8 + a*26 + b*22
print(round(x/88,2))

import requests

url = "https://raw.githubusercontent.com/codesughosh/CSBS-LAB/main/Object%20Oriented%20Programming/2.cpp"

response = requests.get(url)

code_text = response.text
