console.log("This is a test")

function getLine(n, lines) {
  return Array.from(lines).find((l) => l.dataset.number == n)
}

function crossrefs(line) {
  const proof = line.parentNode
  const lines = proof.querySelectorAll(".proof-line")
  const refs = line.dataset.crossrefs.split(",").map((n) => Number(n))
  return refs.map((ref) => getLine(ref, lines))
}

function highlightPrimary(line) {
  line.style.backgroundColor = "lightgray"
  line.style.transition = "background-color 0.1s linear"
}

function highlightSecondary(line) {
  line.style.backgroundColor = "whitesmoke"
  line.style.transition = "background-color 0.1s linear"
}

function unhighlight(line) {
  line.style.backgroundColor = "white"
}

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".lproof").forEach((proof) => {
    const lines = proof.querySelectorAll(".proof-line")
    lines.forEach((line, index, lines) => {
      if (!line.dataset.ellipses) {
        line.addEventListener("mouseenter", (e) => {
          line = e.target
          highlightPrimary(line)
          if (line.dataset.crossrefs) {
            crossrefs(line).forEach(highlightSecondary)
          }
        })
        line.addEventListener("mouseleave", (e) => {
          line = e.target
          unhighlight(line)
          if (line.dataset.crossrefs) {
            crossrefs(line).forEach(unhighlight)
          }
        })
      }
    })
  })
})
