quarto.doc.add_html_dependency({
    name = "lproof",
    version = "1.0.0",
    stylesheets = { "lproof.min.css" }
})

local loc = lpeg.locale()
local S = (loc.space - lpeg.P("\n")) ^ 0 -- inline whitespace

local function trimRight(str)
    --[[
        Remove trailing inline whitespace from string
    ]]
    return (S * lpeg.C(lpeg.P(1) ^ 1) / string.reverse):match(string.reverse(str))
end

local function readString(str)
    --[[
        Read a string with all pandoc input options and return list of inlines
    ]]
    doc = pandoc.read(str, "markdown")
    return doc.blocks[1].content
end

local function readStringAsMath(str)
    --[[
        Read a string in implied math-mode with all pandoc input options and return list of inlines
    ]]
    doc = pandoc.read("$" .. str .. "$", "markdown")
    return doc.blocks[1].content
end

local function proofLineTable(lineNumber, depth, isHypothesis, formula, justification)
    --[[
        A table containing all the information to render a line in a proof
    ]]
    return {
        lineIndex = lineNumber["index"],
        lineNumber = lineNumber["number"],
        depth = depth,
        isHypothesis = isHypothesis,
        formula = formula,
        justification = justification
    }
end

local function parseProof(proofStr)
    --[[
        Parse a text string representing a proof. Return an array of tables, each
        of which represents a line in the proof. The parsed proof can then be sent to ProofToHTML or
        ProofToLaTeX for writing.
    ]]

    -- Sub-Patterns for parsing lines in a proof
    local lineNumber = (S * (("(" * S * ((lpeg.P(1) - ")") ^ 1 / trimRight) * ")" * S) + lpeg.Cc(nil)) *
            ((lpeg.P(1) - ".") ^ 1 / trimRight) * "." * S) /
        function(index, number) return { index = index, number = number } end
    local indentMarker = "|" * S
    local depth = (lpeg.C(indentMarker) ^ 1 / function(...) return #{ ... } end) + lpeg.Cc(0)
    local hypothesisMarker = "_" * S
    local isHypothesis = (hypothesisMarker / function() return true end) + lpeg.Cc(nil)
    local formula = lpeg.C((lpeg.P(1) - lpeg.S("[\n")) ^ 1) / trimRight
    --local justification = S * lpeg.C((lpeg.P(1) - lpeg.S ":]") ^ 1) / trimRight
    --local justification = S * lpeg.C((lpeg.P(1) - lpeg.S "]") ^ 1) / trimRight
    --local num = loc.digit ^ 1
    --local numEntry = (lpeg.C(num * S * "-" * S * num) + lpeg.C(num)) * S
    --local numList = ":" * S * (lpeg.Ct(numEntry * ("," * S * numEntry) ^ 0) / commaSepStr)
    --local ground = ("[" * justification * (numList) ^ -1 * "]" * lpeg.P(" ") ^ 0) ^ -1
    local justification = ("[" * S * lpeg.C((lpeg.P(1) - lpeg.S "]") ^ 1) / trimRight * "]" * S) ^ -1

    -- Pattern for a line in a proof
    local proofLine = lineNumber * depth * isHypothesis * formula * justification * (lpeg.P("\n") + -1)

    -- Pattern for a proof
    local proof = lpeg.Ct((proofLine / proofLineTable) ^ 1)
    return proof:match(proofStr)
end

local function proofToHTML(t)
    --[[
      Create AST elements for HTML rendering of a proof. Proper rendering requires link to
      stylesheet proof.css
    ]]
    setmetatable(t, { __index = { asMath = false } })
    proof = t["proof"]
    asMath = t["asMath"]

    local lines = {}
    for _, proofLine in ipairs(proof) do
        -- Content describing a line in a proof
        local content = {}

        -- Add line number to content; display line index if supplied
        local lineNumber
        if proofLine["lineIndex"] then
            lineNumber = pandoc.Span(readString(proofLine["lineIndex"]))
        else
            lineNumber = pandoc.Span(readString(proofLine["lineNumber"]))
        end
        lineNumber.classes = { "line-number" }
        content[#content + 1] = lineNumber

        -- Add indent markers to content
        for _ = 1, proofLine["depth"] - 1 do
            local levelMarker = pandoc.Span ""
            levelMarker.classes = { "level-marker" }
            content[#content + 1] = levelMarker
        end

        -- Add final indent marker to content
        if proofLine["depth"] >= 1 then
            local formulaMarker = pandoc.Span ""
            if proofLine["isHypothesis"] then
                formulaMarker.classes = { "hypothesis-marker" }
            else
                formulaMarker.classes = { "subproof-marker" }
            end
            table.insert(content, 1, formulaMarker)
        end

        -- Add formula to content
        local formulaContent
        if asMath then
            formulaContent = readStringAsMath(proofLine["formula"])
        else
            formulaContent = readString(proofLine["formula"])
        end
        local formula = pandoc.Span(formulaContent)
        formula.classes = { "proof-formula" }
        content[#content + 1] = formula

        -- Add justification to content
        if proofLine["justification"] ~= nil then
            local justification = pandoc.Span(readString(proofLine["justification"]))
            justification.classes = { "proof-justification" }
            content[#content + 1] = justification
        end

        -- Store line data as data-attributes for custom CSS formatting
        local line = pandoc.Div(content)
        line.classes = { "proof-line" }
        line.attributes["data-number"] = proofLine["lineNumber"]
        line.attributes["data-depth"] = proofLine["depth"]
        if proofLine["isHypothesis"] == true then
            line.attributes["data-hypothesis"] = "true"
        end
        lines[#lines + 1] = line -- list of .proof-line divs
    end
    local proofDiv = pandoc.Div(lines)
    proofDiv.classes = { "lproof" }
    return proofDiv
end

function Div(div)
    if div.classes[1] == "lproof" then
        local proofStr = div.content[1].text
        local proof = parseProof(proofStr)
        if lpeg.P("html"):match(FORMAT) then -- for HTML formatting
            local proofDiv
            if div.classes[2] == "as-math" then
                proofDiv = proofToHTML { proof = proof, asMath = true }
            else
                proofDiv = proofToHTML { proof = proof }
            end
            return proofDiv
        elseif lpeg.P("latex"):match(FORMAT) then
            return div -- for LaTeX formatting (TODO)
        end
    end
    return div
end
