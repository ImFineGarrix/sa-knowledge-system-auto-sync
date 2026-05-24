// Scroll-triggered reveal + counter animation
// All animations are transform/opacity only — GPU compositor friendly
(function () {
  "use strict";

  function initReveal() {
    var els = document.querySelectorAll(".reveal");
    if (!els.length || !("IntersectionObserver" in window)) {
      els.forEach(function (el) { el.classList.add("in"); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: "0px 0px -10% 0px" });
    els.forEach(function (el) { io.observe(el); });
  }

  function animateCount(el, target, duration) {
    var start = performance.now();
    function step(now) {
      var elapsed = now - start;
      var progress = Math.min(elapsed / duration, 1);
      var eased = 1 - Math.pow(1 - progress, 3);
      var value = Math.floor(target * eased);
      el.textContent = value;
      if (progress < 1) requestAnimationFrame(step);
      else el.textContent = target;
    }
    requestAnimationFrame(step);
  }

  function initCounters() {
    var stats = document.querySelectorAll(".stat__num");
    if (!stats.length) return;
    if (!("IntersectionObserver" in window)) {
      stats.forEach(function (el) {
        var t = parseInt(el.textContent, 10);
        if (!isNaN(t)) animateCount(el, t, 1400);
      });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          var t = parseInt(entry.target.textContent, 10);
          if (!isNaN(t)) animateCount(entry.target, t, 1400);
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.5 });
    stats.forEach(function (el) { io.observe(el); });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      initReveal();
      initCounters();
    });
  } else {
    initReveal();
    initCounters();
  }
})();
