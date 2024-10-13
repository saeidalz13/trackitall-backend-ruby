class ApiSerializer
  def self.serialize_interview_questions(data)
    job_interview_questions = []
    data.map do |element|
      job_interview_questions.push(
        {
          id: element.id,
          question: element.question,
          response: element.response
        }
      )
    end

    { job_interview_questions: }
  end
end
