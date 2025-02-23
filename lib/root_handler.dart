import 'package:flower_giver/gemini_wrapper.dart';
import 'package:shelf/shelf.dart';

Future<Response> rootHandler(
  Request request,
  GeminiWrapper geminiWrapper,
) async {
  final response = await geminiWrapper.getGeminiResponse();

  return Response.ok(
    '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #f6d365 0%, #fda085 100%);
            font-family: 'Arial', sans-serif;
          }
          .container {
            text-align: center;
            padding: 20px;
            width: min(90%, 65ch);
            margin: 0 auto;
          }
          .message {
            color: #ff6b6b;
            font-size: clamp(20px, 6vw, 24px);
            margin: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
          }
          img {
            max-width: 300px;
            border-radius: 15px;
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
          }
        </style>
      </head>
      <body>
        <div class="container">
            <div class="flower">
            <div class="center"></div>
            <div class="petals">
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
              <div class="petal"></div>
            </div>
            </div>
            <style>
            .flower {
              position: relative;
              width: 200px;
              height: 200px;
              margin: 20px auto;
            }
            .center {
              position: absolute;
              top: 50%;
              left: 50%;
              width: 50px;
              height: 50px;
              background: #ffd700;
              border-radius: 50%;
              transform: translate(-50%, -50%);
              z-index: 2;
            }
            .petals {
              position: absolute;
              width: 100%;
              height: 100%;
              animation: rotate 20s infinite linear;
            }
            .petal {
              position: absolute;
              width: 70px;
              height: 70px;
              background: #ff69b4;
              border-radius: 50%;
              top: 50%;
              left: 50%;
              transform-origin: 0 0;
            }
            .petal:nth-child(1) { transform: rotate(0deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(2) { transform: rotate(45deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(3) { transform: rotate(90deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(4) { transform: rotate(135deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(5) { transform: rotate(180deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(6) { transform: rotate(225deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(7) { transform: rotate(270deg) translate(-50%, -50%) translateX(60px); }
            .petal:nth-child(8) { transform: rotate(315deg) translate(-50%, -50%) translateX(60px); }
            @keyframes rotate {
              from { transform: rotate(0deg); }
              to { transform: rotate(360deg); }
            }
            </style>
          <div class="message">
            $response
          </div>
        </div>
      </body>
    </html>
    ''',
    headers: {'content-type': 'text/html'},
  );
}
