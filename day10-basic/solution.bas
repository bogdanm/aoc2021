' Result of parsing an input line (ok, invalid or incomplete)
Enum LineType
    ok
    invalid
    incomplete
End Enum

' Data returned by parse_line: the kind of line and the associated score
Type ParseResult
    kind as LineType
    score as ULongInt
End Type

' Return true if the given char is a starting char, false otherwise
Function is_starting(ByRef l as Const String) As Boolean
    If l = "(" Or l = "[" Or l = "{" Or l = "<" Then
        Return true
    Else
        Return false
    End IF
End Function

' Return the matching opening char for "ch"
Function get_matching(ByRef l as Const String) as String
    if l = "}" Then
        Return "{"
    ElseIf l = "]" Then
        Return "["
    ElseIf l = ">" Then
        Return "<"
    ElseIf l = ")" Then
        Return "("
    End If
End Function

' Return the score for an invalid match
Function get_invalid_score(ByRef l as Const String) As ULongInt
    if l = "}" Then
        Return 1197
    ElseIf l = "]" Then
        Return 57
    ElseIf l = ">" Then
        Return 25137
    ElseIf l = ")" Then
        Return 3
    End If
End Function

' Return the score for an incomplete match
Function get_incopmlete_score(ByRef l as Const String) As ULongInt
    if l = "{" Then
        Return 3
    ElseIf l = "[" Then
        Return 2
    ElseIf l = "<" Then
        Return 4
    ElseIf l = "(" Then
        Return 1
    End If
End Function

' Parse a single line and return its kind and associated score
Function parse_line(ByRef l As Const String) As ParseResult
    Dim st(Len(l)) as String*1 ' stack (simulated in an array) used for parsing the line
    Dim stack_top as Integer = 0
    Dim res as ParseResult
    res.score = 0
    For i As Integer = 0 To Len(l) - 1 ' look in all characters in the string
        Dim ch as String*1 = Chr(l[i]) ' the for loop returns ASCII codes, we need characters
        If is_starting(ch) Then ' found starting char, add it to stack
            st(stack_top) = ch
            stack_top = stack_top + 1
        Else ' this is and ending char, make sure that it matches
            If stack_top = 0 Or st(stack_top - 1) <> get_matching(ch) Then ' match error, this is an invalid line
                res.kind = invalid
                res.score = get_invalid_score(ch)
                Return Res
            Else
                stack_top = stack_top - 1
            End If
        End If
    Next
    If stack_top > 0 Then ' this is an incomplete line
        res.kind = incomplete
        For i As Integer = stack_top - 1 to 0 Step -1
            res.score = res.score * 5 + get_incopmlete_score(st(i))
        Next
    Else
        res.kind = ok
    End If
    Return res
End Function

Dim part1 as ULongInt = 0
Dim part2(1000) as UlongInt ' statically allocated array that holds the results needed for part 2
' Read each line in the input file
Dim f as Integer = FreeFile
Dim invalid_cnt as Integer = 0
Open "input.txt" For Input As #f
Do Until EOF(f)
    Dim s as String
    Line Input #f, s
    Dim res as ParseResult = parse_line(Trim(s, Any "\r\n "))
    If res.kind = invalid Then
        part1 = part1 + res.score
    ElseIf res.kind = incomplete Then
        part2(invalid_cnt) = res.score
        invalid_cnt = invalid_cnt + 1
    End If
Loop
Close #f

print "Part 1:", part1
' For part 2, sort the array and print its middle element. So, remember bubble sort?
For i as Integer = 0 to invalid_cnt - 1
    For j as Integer = i + 1 to invalid_cnt - 1
        If part2(i) > part2(j) Then
            Dim temp as ULongInt = part2(i)
            part2(i) = part2(j)
            part2(j) = temp
        End If
    Next
Next
Dim sol_index as Integer = (invalid_cnt - 1) / 2
print "Part 2:", part2(sol_index)