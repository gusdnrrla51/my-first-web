// api/search-places.js — Vercel Serverless Function
// 브라우저가 이 엔드포인트를 호출 → 서버가 네이버 API 호출
// 키는 환경변수(process.env)에서만 읽히므로 브라우저에 절대 노출되지 않음
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');

  const { query } = req.query;

  if (!query) {
    return res.status(400).json({ error: 'query is required' });
  }

  try {
    const apiUrl = `https://openapi.naver.com/v1/search/local.json?query=${encodeURIComponent(query)}&display=5`;

    const response = await fetch(apiUrl, {
      headers: {
        'X-Naver-Client-Id': process.env.NAVER_CLIENT_ID,
        'X-Naver-Client-Secret': process.env.NAVER_CLIENT_SECRET,
      },
    });

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: 'Naver API 호출 실패' });
  }
}
