import urllib.request, json
from datetime import datetime
from dateutil import tz
import os

#Filename to hold the counter
filename = ".i3/NBAScoresFile.txt"

#If file exists then grab the last counter
if os.path.exists(filename):
    fileReader = open(filename, "r")
    counter = int(fileReader.readlines()[0])
    fileReader.close()
#Else set counter to -1
else:
    counter = -1

#URL of NBA scoreboard json
scoreboard = "https://data.nba.net/10s/prod/v1/20190205/scoreboard.json"

#Open URL
with urllib.request.urlopen(scoreboard) as url:
    #Decode JSON data
    data = json.loads(url.read().decode())
    #Get the number of games for today
    numGames = data["numGames"]
    #Inc counter and mod with number of games
    counter = (counter + 1) % numGames
    #Get current game info
    game = data["games"][counter]

    #Convert UTC time info to local time zone for game start time
    from_zone = tz.tzutc()
    to_zone = tz.tzlocal()
    utc = datetime.strptime(game["startTimeUTC"].replace('T', ' ').replace('.000Z', ''), '%Y-%m-%d %H:%M:%S')
    utc = utc.replace(tzinfo=from_zone)
    gameStart = utc.astimezone(to_zone).strftime('%I:%M %p')

    #Get home and away info
    home = game["hTeam"]
    away = game["vTeam"]
    #Check if game started
    gameStarted = bool(game["isGameActivated"])
    #If game has started then display game info
    if gameStarted:
        print("<span bgcolor='#3b3d3fce'>[" + game["period"]["current"] + " QTR " + game["clock"] + " ]"  +  home["triCode"] + "( " + home["linescore"] + " )" + " @ " + away["triCode"] + "( " + away["linescore"] + " )</span>")
        print("<span bgcolor='#3b3d3fce'>[" + game["period"]["current"] + " QTR " + game["clock"] + " ]"  +  home["triCode"] + "( " + home["linescore"] + " )" + " @ " + away["triCode"] + "( " + away["linescore"] + " )</span>")
    #Else display start time and series info
    else:
        print("<span bgcolor='#3b3d3fce'>[" + gameStart + "] " + away["triCode"] + "(" + away["seriesWin"] + "-" + away["seriesLoss"] + ") @ " + home["triCode"] + "(" + home["seriesWin"] + "-" + home["seriesLoss"] + ")</span>")
        print("<span bgcolor='#3b3d3fce'>[" + gameStart + "] " + away["triCode"] + "(" + away["seriesWin"] + "-" + away["seriesLoss"] + ") @ " + home["triCode"] + "(" + home["seriesWin"] + "-" + home["seriesLoss"] + ")</span>")
#Write counter to file
with open(filename, "w+") as fileWriter:
    fileWriter.write(str(counter))
    fileWriter.close()
