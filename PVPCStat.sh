#!/bin/bash

#Author: David Brau

#Colors:
defaultColor="\e[0m"
boldColor="\e[1m"
underlinedColor="\e[4m"
blinkColor="\e[5m"
redColor="\e[31m"
greenColor="\e[32m"
yellowColor="\e[33m"
blueColor="\e[34m"
magentaColor="\e[35m"
cyanColor="\e[36m"
backgroundColor="\e[40m"
priceColors=("\e[38;5;46m" "\e[38;5;76m" "\e[38;5;106m" "\e[38;5;136m" "\e[38;5;166m" "\e[38;5;196m")

#Hours
hours=("00:00-01:00" "01:00-02:00" "02:00-03:00" "03:00-04:00" "04:00-05:00" "05:00-06:00"
		"06:00-07:00" "07:00-08:00" "08:00-09:00" "09:00-10:00" "10:00-11:00" "11:00-12:00"
		"12:00-13:00" "13:00-14:00" "14:00-15:00" "15:00-16:00" "16:00-17:00" "17:00-18:00"
		"18:00-19:00" "19:00-20:00" "20:00-21:00" "21:00-22:00" "22:00-23:00" "23:00-24:00")

#Auxiliar Functions:
function help(){
	echo "HELP"
}

function bubleSortPrices(){
	for ((i=0; i<${#sortedPrices[@]}; i++)); do
		for ((j=0; j<${#sortedPrices[@]}-${i} - 1; j++)); do
			if [ $(echo "(${sortedPrices[j]} - ${sortedPrices[j+1]}) * 100" | bc -l | cut -d "." -f1) -lt 0 ]
			then
			preBefore=${sortedPrices[j]}
			sortedPrices[j]=${sortedPrices[j+1]}
			sortedPrices[j+1]=${preBefore}
			fi
		done
	done
}

function getkWTimePrices(){
	for ((i=0; i<24; i++)); do
		kWTimePrices+=($(echo "scale=3; ${timePrices[i]} / 1000" | bc -l | sed s/./0./))
	done
}

function getColorPrices(){
	for ((i=0; i<24; i++)); do
		color100=$(echo "scale=2; (${timePrices[i]}-${minPrice})/(${maxPrice}-${minPrice})*100" | bc -l | cut -d "." -f1)
		color25+=($(echo "scale=0; ${color100}/4" | bc -l))
	done
}

function getColorPricesDraw(){
	for ((i=0; i<24; i++)); do
		colorLength=${color25[i]}; lines=0
		actualColor="${priceColors[0]}||${defaultColor}"
		if [[ ${colorLength} -gt 0 ]] && [[ ${colorLength} -le 5 ]]; then
			for ((j=0; j<${colorLength}; j++)); do
				actualColor+="${priceColors[1]}|${defaultColor}"
			done
		elif [[ ${colorLength} -gt 5 ]] && [[ ${colorLength} -le 10 ]]; then
			actualColor+="${priceColors[1]}|||||${defaultColor}"
			for ((j=5; j<${colorLength}; j++)); do
				actualColor+="${priceColors[2]}|${defaultColor}"
			done
		elif [[ ${colorLength} -gt 10 ]] && [[ ${colorLength} -le 15 ]]; then
			actualColor+="${priceColors[1]}|||||${defaultColor}"
			actualColor+="${priceColors[2]}|||||${defaultColor}"
			for ((j=10; j<${colorLength}; j++)); do
				actualColor+="${priceColors[3]}|${defaultColor}"
			done
		elif [[ ${colorLength} -gt 15 ]] && [[ ${colorLength} -le 20 ]]; then
			actualColor+="${priceColors[1]}|||||${defaultColor}"
			actualColor+="${priceColors[2]}|||||${defaultColor}"
			actualColor+="${priceColors[3]}|||||${defaultColor}"
			for ((j=15; j<${colorLength}; j++)); do
				actualColor+="${priceColors[4]}|${defaultColor}"
			done
		elif [[ ${colorLength} -gt 20 ]] && [[ ${colorLength} -le 25 ]]; then
			actualColor+="${priceColors[1]}|||||${defaultColor}"
			actualColor+="${priceColors[2]}|||||${defaultColor}"
			actualColor+="${priceColors[3]}|||||${defaultColor}"
			actualColor+="${priceColors[4]}|||||${defaultColor}"
			for ((j=20; j<${colorLength}; j++)); do
				actualColor+="${priceColors[5]}|${defaultColor}"
			done
		fi
		for ((j=25; j>${colorLength}; j--));do
		actualColor+="_"
		done
		colorPricesDraw+=(${actualColor})
	done
}

function getMaxPrice(){
	maxPrice=${sortedPrices[0]}
}

function getMinPrice(){
	minPrice=${sortedPrices[23]}
}

function getPricesWidth(){
	pricesWidth=$(echo "(${maxPrice} - ${minPrice})" | bc -l)
}

function getMeanPrice(){
	sumPrice=0
	for ((i=0; i<${#timePrices[@]}; i++)); do
		sumPrice=$(echo "${sumPrice} + ${timePrices[i]}" | bc -l)
	done
	meanPrice=$(echo "scale=3; ${sumPrice} / 24" | bc -l)
}

function getStdPrice(){
	sum=0
	for ((i=0; i<${#timePrices[@]}; i++)); do
		sum=$(echo "${sum}+((${timePrices[i]} - ${meanPrice})^2)" | bc -l)
	done
	stdPrice=$(echo "scale=3; sqrt(${sum}/24)" | bc -l)
}

function checkConnection(){
	pingResult="result"
	pingResult+=$(ping -c 1 apidatos.ree.es 2>/dev/null | grep 'received' | cut -d ',' -f2 | cut -d ' ' -f2)
	if ! [ ${pingResult} == "result1" ]; then
		 echo -e "${redColor}${boldColor}[!]${defaultColor}${redColor} Unable to connect with REData API. Please verify your internet connection.${defaultColor}"
		 exit 1
	fi
}

function showTitle(){
	echo -e "${boldColor}"
	echo "    ____  _  _  ____   ___    ____  ____  __  ____ "	
	echo "   (  _ \/ )( \(  _ \ / __)  / ___)(_  _)/ _\(_  _)"
	echo "    ) __/\ \/ / ) __/( (__   \___ \  )( /    \ )(  "
	echo "   (__)   \__/ (__)   \___)  (____/ (__)\_/\_/(__) "
	echo -e "${defaultColor}"
}

function help(){
	echo -e "\n\t${yellowColor} --------------------${defaultColor}"
	echo -e "    ${boldColor}${yellowColor}[?]${defaultColor}${yellowColor}  | PVPC STAT - Help |${defaultColor}"
	echo -e "\t${yellowColor} --------------------${defaultColor}\n"
	echo -e "\t${blueColor} [-d]${defaultColor} Select custom date"
	echo -e "\t\t${greenColor}Format:\t\t\t\t${defaultColor} yyyy-mm-dd"
	echo -e "\t\t${greenColor}Closest date (Default):\t\t${defaultColor} $(date +"%Y-%m-%d") (current date)"
	echo -e "\t\t${greenColor}Oldest date:\t\t\t${defaultColor} 2014-01-01\n"
	echo -e "\t${blueColor} [-h]${defaultColor} Show help panel\n"
	exit 0
}

#Operation Mode:
checkConnection
customDate="false"; while getopts ":d:h" arg; do 
	case $arg in
		d) date=$OPTARG; customDate="true";;
		h) help;;
	esac
done

#Data acquisition:
clear
echo -e "${yellowColor}...LOADING...${defaultColor}"
if [ ${customDate} == "true" ]; then
	time="undefined"; currentHour=25
else
	date=$(date +"%Y-%m-%d"); time=$(date +"%H:%M:%S"); currentHour="$(echo "${time}" | cut -d ':' -f1)"
fi
tput civis
requestURL="https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real\
?start_date=${date}T00:00&end_date=${date}T23:59&time_trunc=hour&geo_limit=peninsular"
JSONDataText=$(curl -s ${requestURL})
if [ $(echo "${JSONDataText}" | grep "errors" | wc -m) -ne "0" ]; then
	echo -e "${redColor}${boldColor}[!]${defaultColor}${redColor} The request returned errors. Please check -h (help) menu.${defaultColor}"
	tput cnorm
	exit 1
fi
timePrices=(); for hour in {0..23}; do
	timePrices+=($(echo $JSONDataText | jq ".included[0].attributes.values[${hour}].value"))
done
sortedPrices=("${timePrices[@]}"); bubleSortPrices; getkWTimePrices
getMaxPrice; getMinPrice; getPricesWidth; getMeanPrice; getStdPrice
getColorPrices; getColorPricesDraw

#Data presentation:
clear
showTitle
echo -ne "\tDate: ${yellowColor}${date}${defaultColor}"
echo -e "\tTime: ${yellowColor}${time}${defaultColor}\n"
echo -e "${yellowColor}  PRICES:${defaultColor}\n"
for ((i=0; i<24; i++)); do
	if [ $(echo "${currentHour} - ${i} " | bc -l) -ne "0" ]; then
		echo -ne "  ${blueColor}${hours[i]}${defaultColor}  ${colorPricesDraw[i]}  ${boldColor}${kWTimePrices[i]}${defaultColor} €/kWh"
	else
		echo -ne "  ${boldColor}${backgroundColor}${hours[i]}${defaultColor}  ${colorPricesDraw[i]}  ${boldColor}${backgroundColor}${kWTimePrices[i]} €/kWh${defaultColor}"
	fi
	echo -ne "\n"
done
echo -e "\n"
echo -e "${yellowColor}  STATISTICS:${defaultColor}\n"
echo -ne "${priceColors[1]}${boldColor}\tmin:  ${defaultColor}" 
echo -ne "${boldColor}$(echo "scale=3; ${minPrice}/1000" | bc -l | sed s/./0./)${defaultColor} €/kWh"
echo -ne "\t${priceColors[3]}${boldColor}mean:  ${defaultColor}" 
echo -e "${boldColor}$(echo "scale=3; ${meanPrice}/1000" | bc -l | sed s/./0./)${defaultColor} €/kWh"
echo -ne "${priceColors[5]}${boldColor}\tmax:  ${defaultColor}" 
echo -ne "${boldColor}$(echo "scale=3; ${maxPrice}/1000" | bc -l | sed s/./0./)${defaultColor} €/kWh"
echo -ne "${boldColor}\t std:  ${defaultColor}" 
echo -e "${boldColor}$(echo "scale=3; ${stdPrice}/1000" | bc -l | sed s/./0./)${defaultColor} €/kWh"
echo -e "\n"
tput cnorm
exit 0

