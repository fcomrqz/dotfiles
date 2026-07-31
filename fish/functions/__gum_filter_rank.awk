function score(candidate, plain, pattern, pattern_lower, candidate_lower,
               pattern_length, candidate_length, pattern_index, best_score,
               best_index, total_score, adjacent_bonus, matched_count,
               matched_indexes, last_char, last_index, candidate_index,
               current_char, current_lower, current_score, next_pattern,
               next_candidate, bonus, leading_penalty) {
    plain = candidate
    gsub(/\033\[[^[:alpha:]]*[[:alpha:]]/, "", plain)

    pattern = ENVIRON["GUM_FILTER_QUERY"]
    pattern_lower = tolower(pattern)
    candidate_lower = tolower(plain)
    pattern_length = length(pattern)
    candidate_length = length(plain)
    pattern_index = 1
    best_score = -1
    best_index = 0
    total_score = 0
    adjacent_bonus = 0
    matched_count = 0
    matched_indexes = ""
    last_char = ""
    last_index = 0

    for (candidate_index = 1; candidate_index <= candidate_length; candidate_index++) {
        current_char = substr(plain, candidate_index, 1)
        current_lower = substr(candidate_lower, candidate_index, 1)

        if (current_lower == substr(pattern_lower, pattern_index, 1)) {
            current_score = 0
            if (candidate_index == 1)
                current_score += 10
            if (last_char ~ /^[a-z]$/ && current_char ~ /^[A-Z]$/)
                current_score += 20
            if (candidate_index != 1 &&
                (last_char == "/" || last_char == "-" || last_char == "_" ||
                 last_char == " " || last_char == "." || last_char == "\\"))
                current_score += 20
            if (matched_count > 0 && last_matched_index == last_index) {
                bonus = adjacent_bonus * 2 + 5
                current_score += bonus
                adjacent_bonus += bonus
            }
            if (current_score > best_score) {
                best_score = current_score
                best_index = candidate_index
            }
        }

        next_pattern = ""
        next_candidate = ""
        if (pattern_index < pattern_length)
            next_pattern = substr(pattern_lower, pattern_index + 1, 1)
        if (candidate_index < candidate_length)
            next_candidate = substr(candidate_lower, candidate_index + 1, 1)

        if (next_candidate == "" || next_pattern == next_candidate) {
            if (best_index > 0) {
                if (matched_count == 0) {
                    leading_penalty = (best_index - 1) * -5
                    if (leading_penalty < -15)
                        leading_penalty = -15
                    best_score += leading_penalty
                }
                total_score += best_score
                matched_count++
                matched_indexes = matched_indexes \
                    (matched_count == 1 ? "" : ",") best_index
                last_matched_index = best_index
                best_score = -1
                best_index = 0
                pattern_index++
                if (pattern_index > pattern_length)
                    break
            }
        }

        last_index = candidate_index
        last_char = current_char
    }

    total_score += matched_count - candidate_length
    if (matched_count == pattern_length) {
        scored_value = total_score
        # macOS awk indexes UTF-8 strings by byte. Matching remains correct,
        # but byte offsets would highlight the wrong visible characters.
        scored_indexes = candidate ~ /[^\001-\177]/ ? "" : matched_indexes
        return 1
    }
    return 0
}

{
    candidate_count++
    if (score($0)) {
        print scored_value "\t" candidate_count "\t" scored_indexes
    }
}
