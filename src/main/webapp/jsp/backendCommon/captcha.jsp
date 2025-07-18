<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, java.awt.Graphics2D, java.awt.Color, java.awt.Font, java.awt.image.BufferedImage, javax.imageio.ImageIO" %><%@ include file="common.jsp" %><%!
//   Copyright 2025 HJOW
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

public String createRandomCaptchaKey(int digits) {
    StringBuilder res = new StringBuilder("");
    for(int idx=0; idx<digits; idx++) {
        char ones = (char) ('A' + (int) ( Math.random() * 24 ));
        if(ones == 'O') ones = 'Y';
        if(ones == 'I') ones = 'Z';
        res = res.append(String.valueOf(ones));
    }
    
    return res.toString();
}

public String createCaptcha(String key, int width, int height) {
    return createCaptcha(key, width, height, (Math.random() * 9.9 >= 4.9 ? true : false));
}

public String createCaptcha(String key, int width, int height, boolean darks) {
    return createCaptcha(key, width, height, darks, 20, 5, 15);
}

public String createCaptcha(String key, int width, int height, boolean darks, int noisesCount, int fakeCharCnt, int gaps) {
    try {
        // awt 를 이용해 이미지 데이터 생성
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
     
        // 배경색 설정
        if(darks) g.setColor(new Color( 50,  50,  50));
        else      g.setColor(new Color(200, 200, 200));
        // 배경색 출력
        g.fillRect(0, 0, width, height);
     
        // 폰트 크기 계산
        int fontSize = (int) Math.round(height / 3.0);
        if(fontSize < 10) fontSize = 10;
        g.setFont(new Font("Arial", Font.PLAIN, fontSize));
        
        // 필요 변수 준비
        int i, x, y, randr, randg, randb, fakeCharNo;
        
        // 랜덤 시드 준비
        Random rd1 = new Random();
        Random rd2 = new Random();
        Random rd3 = new Random();
        
        // 가짜 글자 출력
        char[] fakes = {'2', '3', '4', '5', '6', '7', '8', '9', '!', '@', '#', '$', '%', '^', '&'};
        for(i=0; i<fakeCharCnt; i++) {
            x = rd1.nextInt(width)  - gaps;
            y = rd2.nextInt(height);
            
            fakeCharNo = rd1.nextInt(fakes.length);
            
            if(x < gaps) x = gaps;
            if(y < gaps) y = gaps;
            if(x >= width  - gaps) x = width   - gaps; 
            if(y >= height - gaps) y = height  - gaps;
            
            randr = rd3.nextInt(80) - 40;
            randg = rd3.nextInt(80) - 40;
            randb = rd3.nextInt(80) - 40;
            
            if(darks) g.setColor(new Color(100 + randr, 100 + randg, 100 + randb));
            else      g.setColor(new Color(200 + randr, 200 + randg, 200 + randb));
            
            // (i * (fontSize + 1)) + rd.nextInt(fontSize / 2) + 10, rd.nextInt(height - fontSize - 2) - 5
            g.drawString(String.valueOf(fakes[fakeCharNo]), x, y);
        }
        
        // 본 글자 출력
        g.setFont(new Font("Arial", Font.BOLD, fontSize));
        x = gaps;
        for(i=0; i<key.length(); i++) {
            x += (width / (key.length() + 2)) + rd1.nextInt( fontSize / 2 );
            y =  rd2.nextInt((int) Math.round(height - (gaps / 2.0))) + (int) Math.round(gaps / 2.0);
            
            if(x < gaps) x = gaps;
            if(y < gaps) y = gaps;
            if(x >= width  - gaps) x = width   - gaps; 
            if(y >= height - gaps) y = height  - gaps;
            
            randr = rd3.nextInt(80) - 40;
            randg = rd3.nextInt(80) - 40;
            randb = rd3.nextInt(80) - 40;
            
            if(darks) g.setColor(new Color(200 + randr, 200 + randg, 200 + randb));
            else      g.setColor(new Color( 50 + randr,  50 + randg,  50 + randb));
            
            // (i * (fontSize + 1)) + rd.nextInt(fontSize / 2) + 10, rd.nextInt(height - fontSize - 2) - 5
            g.drawString(String.valueOf(key.charAt(i)), x, y);
        }
        
        // 노이즈 출력
        for(i=0; i<noisesCount; i++) {
            g.setColor(new Color( rd3.nextInt(255), rd3.nextInt(255), rd3.nextInt(255) ));
            g.drawLine(rd2.nextInt(width), rd2.nextInt(height), rd2.nextInt(width), rd2.nextInt(height));
        }
        
        // ByteArrayOutputStream 에 이미지 출력
        ByteArrayOutputStream collector = new ByteArrayOutputStream();
        ImageIO.write(image, "png", collector);
        image = null;
        
        byte[] binaries = collector.toByteArray();
        collector = null;
        
        // BASE64 처리
        String base64str = Base64.getEncoder().encodeToString(binaries);
        binaries = null;
        
        // img 태그에서 인식할 수 있도록 프리픽스 붙여서 반환
        return "data:image/png;base64," + base64str;
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    }
}
%>