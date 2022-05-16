import sys
import pyaudio
import audioop
import aiohttp
import asyncio

#Static variables
FORMAT = pyaudio.paInt16
CHUNK = 4096
WIDTH = 2
CHANNELS = 1
RATE = 44100
FACTOR = 2

async def main():
    if(len(sys.argv) != 4):
        print('Invalid number of arguments! Usage: python3 measure.py seconds url auth_token')
        exit()
    arg_record_seconds = sys.argv[1]
    arg_url = sys.argv[2]
    arg_auth_token = sys.argv[3]

    try:
        arg_record_seconds_int = int(arg_record_seconds)
    except ValueError:
        # Handle the exception
        print('Invalid number of seconds, please enter an integer')
    if(arg_record_seconds_int < 1):
        print('Invalid number of seconds, check input')
        exit()
    if(len(arg_url) < 10):
        print('Invalid URL, check input')
        exit()
    if(len(arg_auth_token) < 10):
        print('Invalid auth_token, check input')
        exit()

    global RECORD_SECONDS
    RECORD_SECONDS = arg_record_seconds_int
    global URL
    URL = arg_url
    global AUTH_TOKEN
    AUTH_TOKEN = arg_auth_token

    print(RECORD_SECONDS)
    print(URL)
    print(AUTH_TOKEN)

    await measure()

async def measure():
    #async stuff
    loop = asyncio.get_event_loop()

    # Audio stream stuff
    p = pyaudio.PyAudio()

    stream = p.open(format=FORMAT,
                    channels=CHANNELS,
                    rate=RATE,
                    input=True,
                    output=False,
                    frames_per_buffer=CHUNK)

    # HTTP session stuff
    headers={f"Authorization": f'Bearer {AUTH_TOKEN}'}
    #async with aiohttp.ClientSession(headers=headers) as session:
    session = aiohttp.ClientSession(headers=headers)
    print("* recording from microphone")
    for i in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
        result = await loop.run_in_executor(None, take_measurement, stream, i)
        asyncio.create_task(send_measurement(session, result))

    print("* done recording")
    stream.stop_stream()
    stream.close()
    p.terminate()

    #if we don't wait, the last send_measurement task will fail because the session will be closed.
    await asyncio.sleep(1)
    await session.close()

def take_measurement(stream, iteration):
    data = audioop.mul(stream.read(CHUNK), WIDTH, FACTOR)
    transformed = audioop.rms(data, 2)
    print(transformed)
    measurement = {iteration: transformed}
    return measurement

async def send_measurement(session, measurement):
    result = await session.post(URL, json = measurement)
    #print(f'{measurement} : {result.status}')

asyncio.run(main())