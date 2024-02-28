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
    if str == "" then
        return ""
    else
        doc = pandoc.read(str, "markdown")
        return doc.blocks[1].content
    end
end

local function readStringAsMath(str)
    --[[
        Read a string in implied math-mode with all pandoc input options and return list of inlines
    ]]
    doc = pandoc.read("$" .. str .. "$", "markdown")
    return doc.blocks[1].content
end

local function lineNumberKey(proof)
    --[[
        Return an array whose ith element is the index value for line number i (or i if no index
        is given)
    ]]
    local lineNumberKey = {}
    for _, proofLine in ipairs(proof) do
        if proofLine["lineNumber"] then
            if proofLine["lineIndex"] then
                lineNumberKey[proofLine["lineNumber"]] = proofLine["lineIndex"]
            else
                lineNumberKey[proofLine["lineNumber"]] = proofLine["lineNumber"]
            end
        end
    end
    return lineNumberKey
end

local function numArray(refs)
    local nums = {}
    for _, numEntry in ipairs(refs) do
        if type(numEntry) == "number" then
            nums[#nums + 1] = numEntry
        else
            for n = numEntry[1], numEntry[2] do
                nums[#nums + 1] = n
            end
        end
    end
    numString = tostring(nums[1])
    for _, n in ipairs({ table.unpack(nums, 2, #nums) }) do
        numString = numString .. "," .. tostring(n)
    end
    return numString
end

local function refString(refs, key)
    local str = ""
    for _, numEntry in ipairs(refs) do
        if type(numEntry) == "number" then
            str = str .. ", " .. key[numEntry]
        else
            str = str .. ", " .. key[numEntry[1]] .. "-" .. key[numEntry[2]]
        end
    end
    return string.sub(str, 3, #str) -- omit the leading  ", "
end


local function proofLineTable(lineNumber, depth, isHypothesis, formula, justification, refs)
    --[[
        A table containing all the information to render a line in a proof
    ]]
    return {
        lineIndex = lineNumber["index"],
        lineNumber = lineNumber["number"],
        depth = depth,
        isHypothesis = isHypothesis,
        formula = formula,
        justification = justification,
        refs = refs
    }
end

local function ellipsesLine()
    --[[
        Return an ellipsical proof line
    ]]
    return {
        lineIndex = "$\\vdots$",
        lineNumber = false,
        depth = 0,
        formula = "$\\vdots$",
        justification = "",
        isEllipses = true
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
        function(index, number) return { index = index, number = tonumber(number) } end
    local indentMarker = "|" * S
    local depth = (lpeg.C(indentMarker) ^ 1 / function(...) return #{ ... } end) + lpeg.Cc(0)
    local hypothesisMarker = "_" * S
    local isHypothesis = (hypothesisMarker / function() return true end) + lpeg.Cc(nil)
    local formula = lpeg.C((lpeg.P(1) - lpeg.S("[\n")) ^ 1) / trimRight
    --local justification = S * lpeg.C((lpeg.P(1) - lpeg.S ":]") ^ 1) / trimRight
    --local justification = S * lpeg.C((lpeg.P(1) - lpeg.S "]") ^ 1) / trimRight
    local num = loc.digit ^ 1
    local numEntry = (lpeg.Ct((num / tonumber) * S * "-" * S * (num / tonumber)) + (num / tonumber)) * S
    local numList = ":" * S * lpeg.Ct(numEntry * ("," * S * numEntry) ^ 0)
    --local test = ":    1, 2  -  3, 4, 6"
    --quarto.log.output(numList:match(test))
    --local ground = ("[" * justification * (numList) ^ -1 * "]" * lpeg.P(" ") ^ 0) ^ -1
    --local justification = ("[" * S * lpeg.C((lpeg.P(1) - lpeg.S "]") ^ 1) / trimRight * "]" * S) ^ -1

    local justification = ("[" * S * ((lpeg.P(1) - lpeg.S ":]") ^ 1 / trimRight) * numList ^ -1 * S * "]" * S) ^ -1

    --local test = "[ Modus Ponens: 1, 2-3, 4, 5 ]"
    --quarto.log.output(justification:match(test))



    -- Pattern for a line in a proof
    local ellipses = S * "..." * S
    local proofLine = lineNumber * depth * isHypothesis * formula * justification
    proofLine = ((proofLine / proofLineTable) + (ellipses / ellipsesLine)) * (lpeg.P("\n") + -1)

    -- Pattern for a proof
    local proof = lpeg.Ct(proofLine ^ 1)
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
        if proofLine["justification"] then
            local justificationStr = proofLine["justification"]
            if proofLine["refs"] then
                local refStr = refString(proofLine["refs"], lineNumberKey(proof))
                quarto.log.output(refStr)
                justificationStr = justificationStr .. ": " .. refStr
            end
            local justification = pandoc.Span(readString(justificationStr))
            justification.classes = { "proof-justification" }
            content[#content + 1] = justification
        end

        -- Store line data as data-attributes for custom CSS formatting
        local line = pandoc.Div(content)
        line.classes = { "proof-line" }
        if proofLine["lineNumber"] then
            line.attributes["data-number"] = proofLine["lineNumber"]
        end
        line.attributes["data-depth"] = proofLine["depth"]
        if proofLine["isHypothesis"] == true then
            line.attributes["data-hypothesis"] = "true"
        end
        if proofLine["refs"] then
            line.attributes["data-refs"] = numArray(proofLine["refs"])
        end
        if proofLine["isEllipses"] == true then
            line.attributes["data-ellipses"] = "true"
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
        quarto.log.output(proof)
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
