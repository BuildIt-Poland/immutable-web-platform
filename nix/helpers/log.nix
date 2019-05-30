{}:
let 
  yellow = "[33m";
  black = "[30m";
  red = "[31m";
  green = "[32m";
  blue = "[34m";
  magenta = "[35m";
  cyan = "[36m";
  white = "[37m";
  reset = "[0m";

  from="\\033";
  to = "${from}[0m";
  wrap = color: str: "${from}${color}${str} ${to}";

  warning = wrap yellow "WARNING:";
  error = wrap red "ERROR:";
  info = wrap cyan "INFO:";
  message = wrap magenta;
  important = wrap green;
in
{
  error = str: ''
    printf "${error} ${str}\n"
  '';

  warn = str: ''
    printf "${warning} ${str}\n"
  '';

  info = str: ''
    printf "${info} ${str}\n"
  '';

  message = str: ''
    printf "${message ("> " + str)}\n"
  '';

  important = str: ''
    printf "${important ("> " + str)}\n"
  '';
}