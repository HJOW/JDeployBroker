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

public String createCaptcha(String key, int width, int height) {
   try {
      BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
      Graphics2D g = image.createGraphics();

      g.setColor(new Color(255, 255, 255));
      g.fillRect(0, 0, width, height);

      int fontSize = height / 4;
      if(fontSize < 10) fontSize = 10;
      g.setFont(new Font("Arial", Font.BOLD, fontSize));
      g.setColor(new Color(0, 0, 0));

      int i;
      Random rd = new Random();
      for(i=0; i<key.length(); i++) {
        g.drawString(String.valueOf(key.charAt(i)), rd.nextInt(width - 20) + 10, rd.nextInt(height - 10) + 20);
      }

      int noisesCount = 20;
      for(i=0; i<noisesCount; i++) {
        g.setColor(new Color( rd.nextInt(255), rd.nextInt(255), rd.nextInt(255) ));
        g.drawLine(rd.nextInt(width), rd.nextInt(height), rd.nextInt(width), rd.nextInt(height));
      }

      ByteArrayOutputStream collector = new ByteArrayOutputStream();
      ImageIO.write(image, "png", collector);

      return "data:image/png;base64," + Base64.getEncoder().encodeToString(collector.toByteArray());
   } catch(Exception ex) {
       throw new RuntimeException(ex.getMessage(), ex);
   }
}
%>