const { setGlobalOptions } = require("firebase-functions");
const functions = require("firebase-functions");
const fetch = require("node-fetch");

setGlobalOptions({ maxInstances: 10 });

exports.getInterviewFeedback = functions.https.onRequest(async (req, res) => {
  try {
    const { question, answer, jobTitle, company } = req.body;

    const prompt = `
You are a professional interview coach. The candidate is applying for the position of "${jobTitle}" at "${company}".

Interview Question:
"${question}"

Candidate's Answer:
"${answer}"

Please respond in EXACTLY this format:

FEEDBACK: <Write feedback>
SAMPLE_RESPONSE: <Write sample answer>
`;

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=AQ.Ab8RN6JBlcjmL596_9bxZNJv9d1BiW5_O4JHb2V6NWIWC1d_8Q",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }]
        })
      }
    );

    const data = await response.json();

    let text = "";

    if (
      data.candidates &&
      data.candidates[0] &&
      data.candidates[0].content &&
      data.candidates[0].content.parts &&
      data.candidates[0].content.parts[0]
    ) {
      text = data.candidates[0].content.parts[0].text;
    }

    res.json({ text });

  } catch (error) {
    res.status(500).json({ error: error.toString() });
  }
});