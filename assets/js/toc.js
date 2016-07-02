/* Heading anchor generation based on
 * https://byparker.com/blog/2014/header-anchor-links-in-vanilla-javascript-for-github-pages-and-jekyll/
 */

document.onreadystatechange = function () {
  if (this.readyState === "complete") {
    /* Create anchors for headings h2-h5 */
    for (var level = 2; level <= 5; level++) {
      var headers = document.getElementsByClassName("content")[0].getElementsByTagName("h" + level);
      for (var i = 0; i < headers.length; i++) {
        var header = headers[i];

        if (typeof header.id !== "undefined" && header.id !== "") {
          var anchor = document.createElement("a");
          anchor.className = "header-link";
          anchor.href      = "#" + header.id;
          anchor.innerHTML = "<i class=\"fa fa-link\" aria-hidden=\"true\"></i>";
          header.appendChild(anchor);
        }
      }
    }

    /* Initialize tocbot */
    tocbot.init({
      tocSelector: '.scroll-toc .toc .js-toc',
      contentSelector: '.content',
      headingSelector: 'h2, h3, h4',
      positionFixedSelector: '.scroll-toc',
      headingsOffset: 35,
    });
  }
};
