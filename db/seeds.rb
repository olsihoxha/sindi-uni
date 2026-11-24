# Idempotent: creates missing demo records without resetting existing passwords or grades.
password = ENV.fetch("DEMO_PASSWORD", "LearnWell2026")
if Rails.env.production? && ENV["DEMO_PASSWORD"].blank?
  abort "Set DEMO_PASSWORD to a strong password before seeding production."
end
User.find_or_create_by!(email: "instructor@example.com") do |user|
  user.assign_attributes(name: "Elira", surname: "Dervishi", role: "instructor", password: password)
end
names = [["Sindi", "Kola"], ["Arben", "Hoxha"], ["Era", "Dervishi"], ["Noel", "Leka"], ["Sara", "Basha"], ["Luan", "Meta"], ["Ana", "Koci"], ["Enea", "Duka"], ["Mia", "Shala"], ["Dion", "Gjoni"]]
students = names.map.with_index do |(name, surname), index|
  User.find_or_create_by!(email: "student#{index + 1}@example.com") do |user|
    user.assign_attributes(name: name, surname: surname, role: "student", password: password)
  end
end
catalog = [
  ["CS403", "Engineering Advanced Web Applications", "Design and build reliable web applications, from thoughtful data models to secure APIs and expressive user interfaces."],
  ["CS301", "Data Structures & Algorithms", "Explore the structures behind efficient software: trees, graphs, hashing, sorting and algorithmic problem solving."],
  ["CS305", "Database Systems", "Model real-world information with relational databases. Practice SQL, normalization, transactions and query optimization."],
  ["CS310", "Software Engineering", "Turn requirements into maintainable software through architecture, testing, collaboration and iterative delivery."],
  ["CS201", "Object-Oriented Programming", "Build a strong foundation in objects, abstraction, inheritance and reusable software design."],
  ["CS315", "Computer Networks", "Understand how connected systems communicate, from network protocols and routing to application-layer services."],
  ["CS320", "Human-Computer Interaction", "Create usable, accessible experiences through user research, interaction design and iterative evaluation."],
  ["CS330", "Artificial Intelligence", "Study search, reasoning and intelligent systems through practical computational approaches."],
  ["CS210", "Operating Systems", "Explore processes, memory, concurrency and the foundations that keep modern computers running."],
  ["CS101", "Introduction to Programming", "Learn to think computationally and express ideas through programs, functions and structured problem solving."]
]
Course.transaction do
  catalog.each_with_index do |(code, name, description), index|
    course = Course.find_or_create_by!(code: code) do |item|
      item.assign_attributes(name: name, semester: Semester.recent[index / 2], catalog_data: description)
    end
    assessments = [["Midterm", "0.25"], ["Project", "0.35"], ["Final Exam", "0.40"]].map do |title, weight|
      course.assessments.find_or_create_by!(title: title) { |item| item.weight = weight }
    end
    students.each_with_index do |student, student_index|
      enrollment = course.enrollments.find_or_create_by!(student: student)
      assessments.each_with_index do |assessment, assessment_index|
        enrollment.grades.find_or_create_by!(assessment: assessment) do |grade|
          grade.value = 60 + ((index * 7 + student_index * 3 + assessment_index * 11) % 41)
        end
      end
    end
  end
end
puts "Seeded #{User.where(role: 'instructor').count} instructor(s), #{User.students.count} students, #{Course.count} courses and #{Grade.count} grades."
