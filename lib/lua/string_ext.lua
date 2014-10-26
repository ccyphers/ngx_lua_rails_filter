string_sub_for_nth_match_ct = 0

function string.num_matches(str, pattern)
  ct = 0
  for i in string.gmatch(str, pattern) do
    ct = ct + 1
  end
  return ct
end


function string.sub_for_nth_match(str, pattern, n)
  if not string_sub_for_nth_match_ct then
    string_sub_for_nth_match_ct = 0
  end

  if n == 0 then
    local x, y = string.find(str, pattern)
    if x and y then
      return string.sub(str, 1, x-1)
    else
      return str
    end
  end

  if string_sub_for_nth_match_ct < n then
    local x, y = string.find(str, pattern)

    if not (x and y) then
      if string_sub_for_nth_match_ct == 0 then
        return ""
      else
        string_sub_for_nth_match_ct = n + 1
      end
    end

    str = string.sub(str, x+1, #str)
    string_sub_for_nth_match_ct = string_sub_for_nth_match_ct + 1
    return string.sub_for_nth_match(str, pattern, n)
  end
  string_sub_for_nth_match_ct = 0
  return str
end

