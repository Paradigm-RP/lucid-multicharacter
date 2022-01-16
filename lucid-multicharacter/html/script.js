var selectedChar = null;
var WelcomePercentage = "30vh";
let allowedSlots = []
let permissionSystemActive = false
let userCanDeleteCharacter = false
qbMultiCharacters = {};
var Loaded = false;

$(document).ready(function () {
  window.addEventListener("message", function (event) {
    var data = event.data;


    if (data.action == "ui") {
      permissionSystemActive = data.usePermission

      userCanDeleteCharacter = data.userCanDeleteCharacter;
      if (data.toggle) {
        $(".container").show();
        $(".welcomescreen").fadeIn(150);
        qbMultiCharacters.resetAll();

        if (data.allowedSlots != null && permissionSystemActive) {
          data.allowedSlots.forEach((item, index) => {
            allowedSlots.push(item.slot)
          })
        }
        var originalText = "Karakter bilgisi yükleniyor";
        var loadingProgress = 0;
        var loadingDots = 0;
        $("#loading-text").html(originalText);
        var DotsInterval = setInterval(function () {
          $("#loading-text").append(".");
          loadingDots++;
          loadingProgress++;
          if (loadingProgress == 3) {
            originalText = "Karakter bilgisi onaylanıyor";
            $("#loading-text").html(originalText);
          }
          if (loadingProgress == 4) {
            originalText = "Karakter bilgisi yükleniyor";
            $("#loading-text").html(originalText);
          }
          if (loadingProgress == 6) {
            originalText = "Karakter bilgisi onaylanıyor";
            $("#loading-text").html(originalText);
            $('#head').css('display', 'block')

          }
          if (loadingDots == 4) {
            $("#loading-text").html(originalText);
            loadingDots = 0;
          }
        }, 500);

        setTimeout(function () {
          $.post("http://lucid-multicharacter/setupCharacters");
          setTimeout(function () {
            clearInterval(DotsInterval);
            loadingProgress = 0;
            originalText = "Data yükleniyor";
            $(".welcomescreen").fadeOut(150);

            $.post("http://lucid-multicharacter/removeBlur");
          }, 2000);
        }, 2000);
      } else {
        $(".container").fadeOut(250);
        qbMultiCharacters.resetAll();
      }
    }

    if (data.action == "setupCharacters") {
      setupCharacters(event.data.characters);
    }

    if (data.action == "setupCharInfo") {
      setupCharInfo(event.data.chardata);
    }
    if(data.action == "characterDeleted"){
      refreshCharacters()
    }
  });

  $(".datepicker").datepicker();
});


function containValue(num) {
  return allowedSlots.includes(num)
}

let currentSlot = 1;
function setupCharInfo(cData) {
  if (cData == "empty") {
    $("#char-" + currentSlot).html("");
    $("#char-" + currentSlot).css("display", "flex");
    $(".createnew").css("display", "block");
    $("#char-" + currentSlot).html(
      `
      <p>Karakter bilgisi yok yeni bir tane oluştur!</p>
       <div class="icons" style="padding-left:5px;margin-bottom: 10px;">
        <i class="fas fa-arrow-up prev-char"></i>
        <i class="fas fa-arrow-down next-char" ></i>
      </div>
      `
    );
  } else {
    $(".createnew").css("display", "none");

    var gender = "Male";
    if (cData.charinfo.gender == 1) {
      gender = "Female";
    }
    let deleteHrml = ``
    $("#char-" + currentSlot).css("display", "flex");
    $("#char-" + currentSlot).html(
      `<header><img src="${cData.mugshot}" id="mugshot" width="119px"></header>
        <div class="content">
          <div class="fname">${cData.charinfo.firstname + " " + cData.charinfo.lastname
      }</div>
          <div class="job">${cData.job.label}</div>
          <div class="money">${cData.money.bank}$</div>
        </div>
      <div class="icons">
        <i class="fas fa-arrow-up prev-char" ></i>
        <i class="fas fa-arrow-down next-char" ></i>
      </div>
      <div class="buttons">
      <div class="b1"><button class="create"><i class="fas fa-play"></i><span class="name">
                  Oyna</span></button></div>
        ${userCanDeleteCharacter ? `<div class="b2"><button class="delete"><i class="fas fa-minus-square"></i><span class="name"
        >
        Sil</span></button></div>` : ''}

      </div>`
    );

  }
}

function setupCharacters(characters) {
  currentSlot = 1;
  if (characters.length > 0) {
    $.each(characters, function (index, char) {
      $("#char-" + char.cid).html("");
      $("#char-" + char.cid).data("citizenid", char.citizenid);
      setTimeout(function () {
        $("#char-" + char.cid).data("cData", char);
        $("#char-" + char.cid).data("cid", char.cid);
        if (index == 0) {
          setupFirstData();
        }
        if (index == 4) {
          $(".createnew").css("display", "none");
        }
      }, 100);
    });
  } else {
    setupFirstData();
  }
}

$(document).on("click", "#close-log", function (e) {
  e.preventDefault();
  selectedLog = null;
  $(".welcomescreen").css("filter", "none");
  $(".server-log").css("filter", "none");
  $(".server-log-info").fadeOut(250);
  logOpen = false;
});

let selectedTest = null;

$(document).on("click", ".next-char", function (e) {
  if (currentSlot < 4) {
    if (containValue(currentSlot + 1) || !permissionSystemActive) {
 
      $("#char-" + currentSlot).css("display", "none");
      $("#char-" + currentSlot).html("");

      currentSlot += 1;
      selectedChar = $("#char-" + currentSlot);
      let cDataPed = selectedChar.data("cData");
      if (selectedChar.data("cid") == "") {
        setupCharInfo("empty");


        $.post(
          "http://lucid-multicharacter/cDataPed",
          JSON.stringify({
            cData: cDataPed,
          })
        );
      } else {
        setupCharInfo(selectedChar.data("cData"));


        $.post(
          "http://lucid-multicharacter/cDataPed",
          JSON.stringify({
            cData: cDataPed,
          })
        );
      }
    }
  }
});

$(document).on("click", ".prev-char", function (e) {
  if (currentSlot > 1) {
    $("#char-" + currentSlot).css("display", "none");
    $("#char-" + currentSlot).html("");
    currentSlot -= 1;
    selectedChar = $("#char-" + currentSlot);
    let cDataPed = selectedChar.data("cData");
    if (selectedChar.data("cid") == "") {
      setupCharInfo("empty");
      $.post(
        "http://lucid-multicharacter/cDataPed",
        JSON.stringify({
          cData: cDataPed,
        })
      );
    } else {
      setupCharInfo(selectedChar.data("cData"));

      $.post(
        "http://lucid-multicharacter/cDataPed",
        JSON.stringify({
          cData: cDataPed,
        })
      );
    }

  }
});

const setupFirstData = () => {
  selectedChar = $("#char-" + currentSlot);
  let cDataPed = selectedChar.data("cData");
  if (selectedChar.data("cid") == "") {
    $.post(
      "http://lucid-multicharacter/cDataPed",
      JSON.stringify({
        cData: cDataPed,
      })
    );
    setupCharInfo("empty");
  } else {
    $.post(
      "http://lucid-multicharacter/cDataPed",
      JSON.stringify({
        cData: cDataPed,
      })
    );
    setupCharInfo(selectedChar.data("cData"));
  }
};


$(document).on("click", "#accept-delete", function (e) {
  $.post(
    "http://lucid-multicharacter/removeCharacter",
    JSON.stringify({
      citizenid: $(selectedChar).data("citizenid"),
    })
  );
  $(".character-delete").fadeOut(150);
  $(".characters-block").css("filter", "none");
  refreshCharacters();
});

function refreshCharacters() {
  $("#main").html(`
      <div class="char" id="char-1" data-cid=""></div>
      <div class="char" id="char-2" data-cid=""></div>
      <div class="char" id="char-3" data-cid=""></div>
      <div class="char" id="char-4" data-cid=""></div>
       <button class="createnew">Yeni Karakter Oluştur</button>

      `);

  $(".character-exp-btn").css("display", "none");

  setTimeout(function () {
    $(selectedChar).removeClass("char-selected");
    selectedChar = null;
    $.post("http://lucid-multicharacter/setupCharacters");
    $("#play").css({ display: "none" });
    qbMultiCharacters.resetAll();
  }, 100);
}

$(document).on('click', '#create', function (e) {
  e.preventDefault();
  $.post('http://lucid-multicharacter/createNewCharacter', JSON.stringify({
    firstname: $('#first_name').val(),
    lastname: $('#last_name').val(),
    nationality: $('#nationality').val(),
    birthdate: $('#birthdate').val(),
    gender: $('select[name=gender]').val(),
    cid: $(selectedChar).attr("id").replace("char-", ""),
  }));
  $(".container").fadeOut(150);
  $('.characters-list').css("filter", "none");
  $('.character-info').css("filter", "none");
  allowedSlots = [];
  qbMultiCharacters.fadeOutDown('.character-register', '125%', 400);
})


$(document).on("click", ".createnew", function (e) {
  qbMultiCharacters.fadeInDown('.character-register', '1%', 400);
});

$(document).on("click", ".create", function (e) {
  e.preventDefault();
  var charData = $(selectedChar).data("cid");
  var citizenid = $(selectedChar).data("citizenid");
  if (selectedChar !== null) {
    if (charData !== "" && citizenid !== null) {
      $.post(
        "http://lucid-multicharacter/selectCharacter",
        JSON.stringify({
          cData: $(selectedChar).data("cData"),
          citizenid: $(selectedChar).data("citizenid"),
        })
      );

      setTimeout(function () {
        $('#head').css('display', 'none')

        qbMultiCharacters.resetAll();
        allowedSlots = [];
      }, 1500);
    }
  }
});

$(document).on("click", "#delete", function (e) {
  e.preventDefault();
  var charData = $(selectedChar).data("cid");

  if (selectedChar !== null) {
    if (charData !== "") {
      $(".characters-block").css("filter", "blur(2px)");
      $(".character-delete").fadeIn(250);
    }
  }
});

$(document).on("click", ".delete", function (e) {
  e.preventDefault();
  var charData = $(selectedChar).data("citizenid");

  if (selectedChar !== null) {
      $.post(
        "http://lucid-multicharacter/deleteCharacter",
        JSON.stringify({
          citizenid: $(selectedChar).data("citizenid"),
        })
      );
  }
});


qbMultiCharacters.fadeOutUp = function (element, time) {
  $(element)
    .css({ display: "block" })
    .animate({ top: "-80.5%" }, time, function () {
      $(element).css({ display: "none" });
    });
};

qbMultiCharacters.fadeOutDown = function (element, percent, time) {
  if (percent !== undefined) {
    $(element)
      .css({ display: "block" })
      .animate({ top: percent }, time, function () {
        $(element).css({ display: "none" });
      });
  } else {
    $(element)
      .css({ display: "block" })
      .animate({ top: "103.5%" }, time, function () {
        $(element).css({ display: "none" });
      });
  }
};

qbMultiCharacters.fadeInDown = function (element, percent, time) {
  $(element).css({ display: "block" }).animate({ top: percent }, time);
};

qbMultiCharacters.resetAll = function () {
  $(".characters-list").hide();
  $(".characters-list").css("top", "-40");
  $(".character-info").hide();
  $(".character-info").css("top", "-40");
  $(".welcomescreen").css("top", WelcomePercentage);
  $(".server-log").show();
  $(".server-log").css("top", "25%");
  $(".character-exp-btn").css("display", "none");
};
