// Just from https://github.com/adupays/javascript-table-of-contents
// With custom modifications
function TableOfContents(container) {
  this.container = container;
  this.uls = [document.createElement("ul")];
  this.buildStructure();
}

TableOfContents.prototype.buildStructure = function() {
  var titles = this.container.querySelectorAll("h1, h2, h3, h4, h5"),
  lastLvl = 0,
  mapLvl = 0;
  for (var i = 0; i < titles.length; i++) {
    var title = titles[i],
    lvl = parseInt(title.tagName.replace("H", ""), 10);
    if (lvl - lastLvl > 1) {
      mapLvl = lvl - lastLvl - 1;
    } else {
      lastLvl = lvl;
      mapLvl = 0;
    }
    var li = document.createElement("li"),
    a = document.createElement("a");
    a.setAttribute('href', '#' + title.id);
    a.textContent = title.textContent;
    li.appendChild(a);
    if (!this.uls[lvl - mapLvl - 1]) {
      var ul = document.createElement("ul");
      this.uls[lvl - mapLvl - 1] = ul;
      this.uls[lvl - mapLvl - 2].lastChild.appendChild(ul);
    }
    this.uls[lvl - mapLvl] = null;  
    this.uls[lvl - mapLvl - 1].appendChild(li);
  }
};

TableOfContents.prototype.appendTo = function(element) {
  element.appendChild(this.uls[0]);
};

// to initialize a new table of contents on a page, specify the page's wrapper and the table of contents's wrapper
document.addEventListener('DOMContentLoaded', function() {
  var t = new TableOfContents(document.querySelector("#spec"));
  t.appendTo(document.querySelector("#table-of-contents"));

  function showToc() {
    document.querySelector("#toc-popup").style= "display: block;";
  }

  function hideToc() {
    document.querySelector("#toc-popup").style= "display: none;";
  }

  document.querySelector("#show-toc").addEventListener('click', showToc, true);
  document.querySelector("#toc-popup").addEventListener('click', hideToc, true);

  // yay, I love mobile safari
  document.querySelector("#show-toc").addEventListener('touchstart', showToc, true);
  document.querySelector("#show-toc").addEventListener('touchmove', showToc, true);
  document.querySelector("#show-toc").addEventListener('touchend', showToc, true);
  document.querySelector("#toc-popup").addEventListener('touchstart', hideToc, true);
  document.querySelector("#toc-popup").addEventListener('touchmove', hideToc, true);
  document.querySelector("#toc-popup").addEventListener('touchend', hideToc, true);
  document.querySelector("#show-toc").onclick = function () {}
  document.querySelector("#toc-popup").onclick = function () {}
}, false);
