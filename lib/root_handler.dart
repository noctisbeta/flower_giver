import 'package:flower_giver/gemini_wrapper.dart';
import 'package:shelf/shelf.dart';

Future<Response> rootHandler(
  Request request,
  GeminiWrapper geminiWrapper,
) async {
  final String? name = request.url.queryParameters['name'];

  final String content = switch (name) {
    String() => '''
      <div class="message">
        ${await geminiWrapper.customizedResponse(name)}
      </div>
      <button onclick="window.location.href='/'" class="create-button">
        ✨ Create Another
      </button>
      <style>
        .create-button {
          background: #ff69b4;
          color: white;
          border: none;
          padding: 1rem 2.5rem;
          border-radius: 25px;
          cursor: pointer;
          font-size: 1.1rem;
          font-weight: 600;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(255, 105, 180, 0.3);
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-top: 2rem;
        }
        
        .create-button:hover {
          background: #ff4da6;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(255, 105, 180, 0.4);
        }
        
        .create-button:active {
          transform: translateY(1px);
          box-shadow: 0 2px 10px rgba(255, 105, 180, 0.2);
        }
      </style>
    ''',
    null => '''
      <div class="form-container">
        <h2>Share a Flower</h2>
        <p>Enter a name to create a personalized flower message</p>
        <div class="input-group">
          <input type="text" id="nameInput" placeholder="Enter name..." />
          <button onclick="shareFlower()" class="share-button">Give Flower</button>
        </div>
        <div id="toast" class="toast"></div>
      </div>
      <script>
        function showToast(message) {
          const toast = document.getElementById('toast');
          toast.textContent = message;
          toast.classList.add('show');
          setTimeout(() => toast.classList.remove('show'), 3000);
        }

        function shareFlower() {
          const nameInput = document.getElementById('nameInput');
          const inputName = nameInput.value;
          if (!inputName) return;
          
          const url = new URL(window.location.href);
          url.searchParams.set('name', inputName);
          
          navigator.clipboard.writeText(url.toString())
            .then(() => {
              showToast(`Link copied! Share it with \${inputName} ✨`);
            })
            .catch(() => {
              showToast('Failed to copy link 😔');
            });
        }
      </script>
      <style>
        .form-container {
          background: rgba(255, 255, 255, 0.9);
          padding: 2rem;
          border-radius: 15px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          text-align: center;
        }
        .input-group {
          display: flex;
          gap: 10px;
          margin-top: 1rem;
        }
        #nameInput {
          padding: 0.5rem 1rem;
          border: 2px solid #ff69b4;
          border-radius: 8px;
          font-size: 1rem;
          flex: 1;
        }
        .share-button {
          background: #ff69b4;
          color: white;
          border: none;
          padding: 0.5rem 1.5rem;
          border-radius: 8px;
          cursor: pointer;
          font-size: 1rem;
          transition: background 0.2s;
        }
        .share-button:hover {
          background: #ff4da6;
        }
        .toast {
          visibility: hidden;
          background-color: rgba(0, 0, 0, 0.8);
          color: white;
          text-align: center;
          border-radius: 8px;
          padding: 16px;
          position: fixed;
          z-index: 1;
          left: 50%;
          bottom: 30px;
          transform: translateX(-50%);
          font-size: 0.9rem;
          opacity: 0;
          transition: opacity 0.3s, visibility 0.3s;
        }

        .toast.show {
          visibility: visible;
          opacity: 1;
        }
      </style>
    ''',
  };

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
            background: linear-gradient(135deg, #fff0f6 0%, #ffa7c4 100%);
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
          .flower {
            position: relative;
            width: 250px;
            height: 250px;
            margin: 40px auto;
          }
          .center {
            position: absolute;
            top: 50%;
            left: 50%;
            width: 60px;
            height: 60px;
            background: radial-gradient(circle at 40% 40%, #ffd700, #ff8c00);
            border-radius: 50%;
            transform: translate(-50%, -50%);
            z-index: 2;
            box-shadow: inset -3px -3px 8px rgba(0,0,0,0.2);
          }
          .petals {
            position: absolute;
            width: 100%;
            height: 100%;
            animation: rotate 25s infinite linear;
            transform-origin: center;
          }
          .petal {
            position: absolute;
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #ff69b4, #ff1493);
            border-radius: 50% 50% 0 50%;
            top: 50%;
            left: 50%;
            transform-origin: 0 0;
            box-shadow: 2px 2px 8px rgba(0,0,0,0.15);
          }
          .petal:nth-child(1) { transform: rotate(0deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(2) { transform: rotate(45deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(3) { transform: rotate(90deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(4) { transform: rotate(135deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(5) { transform: rotate(180deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(6) { transform: rotate(225deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(7) { transform: rotate(270deg) translate(-50%, -50%) translateX(70px); }
          .petal:nth-child(8) { transform: rotate(315deg) translate(-50%, -50%) translateX(70px); }
          @keyframes rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
          @keyframes sway {
            0% { transform: rotate(var(--rotation)) translate(-50%, -50%) translateX(70px) scale(1); }
            100% { transform: rotate(var(--rotation)) translate(-50%, -50%) translateX(70px) scale(1.1); }
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
          $content
        </div>
      </body>
    </html>
    ''',
    headers: {'content-type': 'text/html'},
  );
}
