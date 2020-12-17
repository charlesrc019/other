var codes = null
var view = false
var txt = document.getElementById("code")
var rvl = document.getElementById("reveal")
var btn = document.getElementById("submit")
var err = document.getElementById("error")
var frm = document.getElementById("form")
document.addEventListener("DOMContentLoaded", codeLoad)
rvl.addEventListener("click", codeReveal)
btn.addEventListener("click", codeCheck)
txt.addEventListener("keyup", function(event){
  var key=event.keyCode || event.which;
   if (key === 13) {
      event.preventDefault()
      codeCheck();
   }
})

function codeLoad(){
  var request = new XMLHttpRequest();
  request.open("GET", "codes.csv", true);
  request.send(null);
  request.onreadystatechange = function () {
    if (request.status !== 200) {
      alert("ERROR 404.\nUnable to fetch secret code CSV.")
    }
    if (request.readyState === 4 && request.status === 200) {
      var type = request.getResponseHeader("Content-Type");
      if (type.indexOf("text") !== 1) {
        var lines = request.responseText.split("\n")
        var result = lines.map(function(line) {
           return line.split(",")
        })
        codes = result
        return
      }
    }
  }
}

function codeReveal() {
  if (view) {
    rvl.classList.remove("fa-eye-slash")
    rvl.classList.add("fa-eye")
    txt.type = "password"
    view = false
  }
  else {
    rvl.classList.remove("fa-eye")
    rvl.classList.add("fa-eye-slash")
    txt.type = "text"
    view = true
  }
}

function codeCheck() {
  var code = txt.value.toLowerCase()
  var link = null
  if ((/\S/.test(code)) && code !== null)
  for (i = 0; i < codes.length; i++) {
    if (codes[i][0].toLowerCase() === code) {
      link = codes[i][1]
    }
  }
  if (link !== null) {
    window.location = link
  }
  else {
    errWarn()
    setTimeout(errHide, 5000)
    return false
  }
}

function errWarn() {
  err.classList.remove("d-none")
}

function errHide() {
  err.classList.add("d-none")
}