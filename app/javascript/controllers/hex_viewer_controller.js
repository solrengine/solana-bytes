import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cell", "tooltip"]

  connect() {
    this.isTouch = "ontouchstart" in window
    this.activeRegion = null
    this.highlightedCells = []

    // Grab reference before moving out of controller scope
    this.tip = this.tooltipTarget
    document.body.appendChild(this.tip)
  }

  disconnect() {
    this.tip.remove()
  }

  cellTargetConnected(cell) {
    if (this.isTouch) {
      cell.addEventListener("click", this.handleTap.bind(this))
    } else {
      cell.addEventListener("mouseenter", this.handleMouseEnter.bind(this))
      cell.addEventListener("mouseleave", this.handleMouseLeave.bind(this))
    }
  }

  handleMouseEnter(event) {
    this.activateRegion(event.currentTarget)
  }

  handleMouseLeave() {
    this.deactivateRegion()
  }

  handleTap(event) {
    const cell = event.currentTarget
    const regionId = cell.dataset.region

    if (this.activeRegion === regionId) {
      this.deactivateRegion()
      this.activeRegion = null
    } else {
      this.deactivateRegion()
      this.activateRegion(cell)
      this.activeRegion = regionId
    }
  }

  activateRegion(cell) {
    const regionId = cell.dataset.region
    if (!regionId) return

    const regionCells = this.cellTargets.filter(c => c.dataset.region === regionId)

    regionCells.forEach(c => {
      c.style.background = "rgba(255,255,255,0.2)"
      c.style.color = "#ffffff"
      c.style.outline = "1px solid rgba(255,255,255,0.4)"
      c.style.outlineOffset = "-1px"
    })

    this.highlightedCells = regionCells
    this.showTooltip(cell)
  }

  deactivateRegion() {
    this.highlightedCells.forEach(c => {
      c.style.background = c.dataset.baseBg
      c.style.color = c.dataset.baseColor
      c.style.outline = ""
      c.style.outlineOffset = ""
    })
    this.highlightedCells = []
    this.hideTooltip()
  }

  showTooltip(cell) {
    const tip = this.tip
    const regionName = cell.dataset.regionName
    const regionDecoded = cell.dataset.regionDecoded
    const regionStart = parseInt(cell.dataset.regionStart)
    const regionLength = parseInt(cell.dataset.regionLength)
    const offset = parseInt(cell.dataset.offset)
    const hex = cell.dataset.value
    const decimal = parseInt(cell.dataset.decimal)

    let html = ""

    if (regionName) {
      html += `<div style="color:#fff;font-weight:600;margin-bottom:4px">${regionName}</div>`
      if (regionDecoded) {
        html += `<div style="color:#d1d5db;word-break:break-all;margin-bottom:4px">${regionDecoded}</div>`
      }
      html += `<div style="color:#6b7280;font-size:10px">Bytes ${regionStart}\u2013${regionStart + regionLength - 1} (${regionLength} bytes)</div>`
    }

    const char = decimal >= 32 && decimal <= 126 ? String.fromCharCode(decimal) : "\u00B7"
    html += `<div style="color:#6b7280;font-size:10px;margin-top:4px;border-top:1px solid #374151;padding-top:4px">`
    html += `Offset 0x${offset.toString(16).padStart(4, "0")} \u00B7 0x${hex} \u00B7 ${decimal} \u00B7 '${char}'`
    html += `</div>`

    tip.innerHTML = html
    tip.style.display = "block"

    const rect = cell.getBoundingClientRect()

    // Reset position to measure
    tip.style.left = "0px"
    tip.style.top = "0px"
    const tipRect = tip.getBoundingClientRect()

    let left = rect.left + rect.width / 2 - tipRect.width / 2
    let top = rect.top - tipRect.height - 8

    if (top < 8) top = rect.bottom + 8
    if (left < 8) left = 8
    if (left + tipRect.width > window.innerWidth - 8) {
      left = window.innerWidth - tipRect.width - 8
    }

    tip.style.left = `${left}px`
    tip.style.top = `${top}px`
  }

  hideTooltip() {
    this.tip.style.display = "none"
  }
}
