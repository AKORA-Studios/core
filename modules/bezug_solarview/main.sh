#!/bin/sh

#
# OpenWB-Modul für die Anbindung von SolarView über den integrierten TCP-Server
# Details zur API: https://solarview.info/solarview-fb_Installieren.pdf
#

. /var/www/html/openWB/openwb.conf

# Checks
if [ -z "$solarview_hostname" ]; then
  >&2 echo "Missing required variable 'solarview_hostname'"
  return 1
fi
if [ "${solarview_port}" ]; then
  if [ "$solarview_port" -lt 1 ] || [ "$solarview_port" -gt 65535 ]; then
    >&2 echo "Invalid value '$solarview_port' for variable 'solarview_port'"
    return 1
  fi
fi


request() {
  command="$1"
  port="${solarview_port:-15000}"
  timeout="${solarview_timeout:-1}"

  response=$(echo "$command" | nc -w "$timeout" "$solarview_hostname" "$port")
  return_code="$?"
  if [ "$return_code" -ne 0 ]; then
    >&2 echo "Error: request to SolarView failed. Details: return-code: '$return_code', host: '$solarview_hostname', port: '$port', timeout: '$timeout'"
    return "$return_code"
  fi

  [ "$debug" -ne 0 ] && >&2 echo "Raw response: $response"
  #
  # Format:    {WR,Tag,Monat,Jahr,Stunde,Minute,KDY,KMT,KYR,KT0,PAC,???,???,UL1,IL1,UL2,IL2,UL3,IL3,TKK},Checksum
  # Beispiele: {22,09,09,2019,10,37,0001.2,00024,000903,00007817,01365,000,000.0,000,000.0,000,000.0,000,000.0,00},:
  #            {21,09,09,2019,10,37,0002.3,00141,004233,00029525,01365,000,000.0,000,000.0,000,000.0,000,000.0,00},;
  #
  # Bedeutung (siehe SolarView-Dokumentation):
  #  KDY= Tagesertrag (kWh)
  #  KMT= Monatsertrag (kWh)
  #  KYR= Jahresertrag (kWh)
  #  KT0= Gesamtertrag (kWh)
  #  PAC= Generatorleistung in W
  #  UL1, IL1= Netzspannung, Netzstrom Phase 1
  #  UL2, IL2= Netzspannung, Netzstrom Phase 2
  #  UL3, IL3= Netzspannung, Netzstrom Phase 3
  #  TKK= Temperatur Wechselrichter

  # Geschweifte Klammern und Checksumme entfernen
  values="${response#*\{}"
  values="${values%\}*}"

  # Werte auslesen und verarbeiten
  local LANG=C
  local IFS=','
  echo "$values" | while read -r WR Tag Monat Jahr Stunde Minute KDY KMT KYR KT0 PAC UDC IDC UDCB IDCB UDCC IDCC X1 X2 UL1 IL1 UL2 IL2 UL3 IL3 TKK
  do

    # Werte formatiert in Variablen speichern
    id="$WR"
    timestamp="$Jahr-$Monat-$Tag $Stunde:$Minute"
    #  PAC = '-0357' bedeutet: 357 W Bezug, 0 W Einspeisung
    #  PAC =  '0246' bedeutet: 0 W Bezug, 246 W Einspeisung
    power=$(printf "%.0f" "$PAC")
    power=$(expr -1 \* "$power")
    energy_day=$(printf "%.1f" "$KDY")
    energy_month=$(printf "%.0f" "$KMT")
    energy_year=$(printf "%.0f" "$KYR")
    energy_total=$(printf "%.0f" "$KT0")
    x1=$(printf "%.0f" "$X1")
    x2=$(printf "%.1f" "$X2")
    grid1_voltage=$(printf "%.0f" "$UL1")
    grid1_current=$(printf "%.1f" "$IL1")
    grid2_voltage=$(printf "%.0f" "$UL2")
    grid2_current=$(printf "%.1f" "$IL2")
    grid3_voltage=$(printf "%.0f" "$UL3")
    grid3_current=$(printf "%.1f" "$IL3")
    temperature=$(printf "%.0f" "$TKK")

    if [ "$debug" -ne 0 ]; then
      # Werte ausgeben
      >&2 echo "ID: $id"
      >&2 echo "Zeitpunkt: $timestamp"
      >&2 echo "Temperatur: $temperature °C"
      >&2 echo "Leistung: $power W"
      >&2 echo "Energie:"
      >&2 echo "  Tag:    $energy_day kWh"
      >&2 echo "  Monat:  $energy_month kWh"
      >&2 echo "  Jahr:   $energy_year kWh"
      >&2 echo "  Gesamt: $energy_total kWh"
      >&2 echo "Unbekannt 1: $x1"
      >&2 echo "Unbekannt 2: $x2"
      >&2 echo "Netz:"
      >&2 echo "  Phase 1:"
      >&2 echo "    Spannung: $grid1_voltage V"
      >&2 echo "    Strom:    $grid1_current A"
      >&2 echo "  Phase 2:"
      >&2 echo "    Spannung: $grid2_voltage V"
      >&2 echo "    Strom:    $grid2_current A"
      >&2 echo "  Phase 3:"
      >&2 echo "    Spannung: $grid3_voltage V"
      >&2 echo "    Strom:    $grid3_current A"
    fi

    # Werte speichern
    if [ "$command" = '21*' ]; then
      echo "$energy_total"  >'/var/www/html/openWB/ramdisk/einspeisungkwh'
    elif [ "$command" = '22*' ]; then
      echo "$power"         >'/var/www/html/openWB/ramdisk/wattbezug'
      echo "$energy_total"  >'/var/www/html/openWB/ramdisk/bezugkwh'
      echo "$grid1_current" >'/var/www/html/openWB/ramdisk/bezuga1'
      echo "$grid2_current" >'/var/www/html/openWB/ramdisk/bezuga2'
      echo "$grid3_current" >'/var/www/html/openWB/ramdisk/bezuga3'
      echo "$grid1_voltage" >'/var/www/html/openWB/ramdisk/evuv1'
      echo "$grid2_voltage" >'/var/www/html/openWB/ramdisk/evuv2'
      echo "$grid3_voltage" >'/var/www/html/openWB/ramdisk/evuv3'
    fi

    # Aktuelle Leistung an der Aufrufer zurückliefern
    echo "$power"
  done
}

# '21*': Einspeisung
request '21*' >/dev/null
# '21*': Bezug
power=$(request '22*')

echo "$power"
