enum Faculty
  BW
  EMI
  MV
  M
end

# Course to faculty mapping
# Help is appreciated here (I don't know where every course belongs to)
BW_COURSES  = ["BW", "BWM", "DEC", "DiW", "IBC", "LH", "WI", "WIN", "WINM", "WINp", "WP"]
EMI_COURSES = ["AI", "AKI", "CME", "EI", "EP", "ES", "INFM", "MA", "ME", "MKA", "MK", "MT", "MTM", "startING"]
MV_COURSES  = ["BM", "BT", "MME", "MPE", "RED", "UT"]
M_COURSES   = ["ENITS", "mgp", "MI", "MuK", "UN", "UV"]

def is_winter
  month = Time.local.month
  month >= 9 || month <= 2
end

def id_to_time(id, faculty)
  case id
  when 0
    {8, 0}
  when 1
    {9, 45}
  when 2
    if is_winter
      case faculty
      when Faculty::BW, Faculty::EMI, Faculty::M
        {11, 35}
      when Faculty::MV
        {12, 0}
      else
        {0, 0}
      end
    else
      case faculty
      when Faculty::BW, Faculty::MV
        {11, 35}
      when Faculty::EMI, Faculty::M
        {12, 0}
      else
        {0, 0}
      end
    end
  when 3
    {14, 0}
  when 4
    {15, 45}
  when 5
    {17, 30}
  else
    {0, 0}
  end
end

def course_to_faculty(course)
  regex_match = /^([a-zA-Z]+)/.match(course)
  base_course = if !regex_match.nil?
                  regex_match[1]
                else
                  nil
                end

  if EMI_COURSES.any? { |c| c == base_course } # EMI first since for performance reasons
    Faculty::EMI
  elsif BW_COURSES.any? { |c| c == base_course }
    Faculty::BW
  elsif MV_COURSES.any? { |c| c == base_course }
    Faculty::MV
  elsif M_COURSES.any? { |c| c == base_course }
    Faculty::M
  else
    Faculty::EMI # EMI is innovative, lol
  end
end
