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
  mapLvl = 0,
  parentId = '',
  parentI = 1;
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
    // let people style appendixes and such differently
    newParentId = title.parentElement.id
    if (parentId != newParentId) {
      parentId = newParentId;
      parentI = 1;
    } else {
      parentI++;
    }
    li.setAttribute('class', 'parent-' + parentId + ' parent-' + parentId + '-' + parentI + ' toc-id-' + title.id);
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
  element.appendChild(this.uls[0].cloneNode(true));
};

function showToc() {
  document.querySelector("#toc-popup").style.display = "block";
}

function hideToc() {
  document.querySelector("#toc-popup").style.display = "none";
}

// to initialize a new table of contents on a page, specify the page's wrapper and the table of contents's wrapper
document.addEventListener('DOMContentLoaded', function() {
  var t = new TableOfContents(document.querySelector("#spec"));
  t.appendTo(document.querySelector("#table-of-contents"));
  t.appendTo(document.querySelector("#printable-toc"));

  // I love mobile browsers so much, they are amazing
  document.querySelector("#show-toc").onclick = function () {showToc();}
  document.querySelector("#toc-popup").onclick = function () {hideToc();}
}, false);
