// LiveNiro fixture: plain Java Swing, no build tool. An equalizer; "Add bar" adds a bar.
import javax.swing.*;
import java.awt.*;

public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("LiveNiro Swing Equalizer");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            int[] bars = {8};
            JPanel canvas = new JPanel() {
                @Override
                protected void paintComponent(Graphics g) {
                    super.paintComponent(g);
                    Graphics2D g2 = (Graphics2D) g;
                    g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                    g2.setColor(new Color(20, 14, 40));
                    g2.fillRect(0, 0, getWidth(), getHeight());
                    double t = System.currentTimeMillis() / 300.0;
                    int w = (getWidth() - 40) / bars[0];
                    for (int i = 0; i < bars[0]; i++) {
                        int h = (int) (40 + 110 * (1 + Math.sin(t + i * 0.7)) );
                        float hue = 0.75f + i * 0.03f;
                        g2.setColor(Color.getHSBColor(hue % 1f, 0.6f, 0.95f));
                        g2.fillRoundRect(20 + i * w + 4, getHeight() - h - 20, w - 8, h, 12, 12);
                    }
                }
            };
            canvas.setPreferredSize(new Dimension(680, 340));
            new Timer(30, e -> canvas.repaint()).start();

            JButton add = new JButton("Add bar");
            JLabel count = new JLabel("8 bars");
            add.addActionListener(e -> {
                bars[0] = Math.min(bars[0] + 1, 24);
                count.setText(bars[0] + " bars");
            });
            JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT, 16, 10));
            controls.add(add);
            controls.add(count);

            frame.add(canvas, BorderLayout.CENTER);
            frame.add(controls, BorderLayout.SOUTH);
            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }
}
