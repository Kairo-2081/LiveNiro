// LiveNiro fixture: Qt 6 Widgets + CMake. A small task board: type a task, press Add.
#include <QApplication>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QProgressBar>
#include <QPushButton>
#include <QTimer>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QWidget window;
    window.setWindowTitle("LiveNiro Qt Tasks");
    window.resize(640, 420);
    window.setStyleSheet(
        "QWidget { background: #17112b; color: #f5f3ff; font-size: 15px; }"
        "QLineEdit, QListWidget { background: #241b3d; border: 1px solid #3b2f5c; border-radius: 8px; padding: 6px; }"
        "QPushButton { background: #8b5cf6; border: none; border-radius: 8px; padding: 8px 18px; font-weight: bold; }"
        "QProgressBar { background: #241b3d; border: none; border-radius: 6px; height: 14px; text-align: center; }"
        "QProgressBar::chunk { background: #ec4899; border-radius: 6px; }");

    auto *title = new QLabel("<b style='font-size:22px'>Sprint board</b>");
    auto *input = new QLineEdit;
    input->setPlaceholderText("New task...");
    auto *add = new QPushButton("Add");
    auto *list = new QListWidget;
    list->addItems({"Design the login screen", "Write the README", "Record the demo"});
    auto *progress = new QProgressBar;
    progress->setRange(0, 100);

    auto *row = new QHBoxLayout;
    row->addWidget(input);
    row->addWidget(add);
    auto *layout = new QVBoxLayout(&window);
    layout->setContentsMargins(24, 20, 24, 20);
    layout->addWidget(title);
    layout->addLayout(row);
    layout->addWidget(list);
    layout->addWidget(progress);

    auto addTask = [&] {
        if (input->text().trimmed().isEmpty()) return;
        list->addItem(input->text());
        input->clear();
    };
    QObject::connect(add, &QPushButton::clicked, addTask);
    QObject::connect(input, &QLineEdit::returnPressed, addTask);

    QTimer timer;
    QObject::connect(&timer, &QTimer::timeout, [&] { progress->setValue((progress->value() + 1) % 101); });
    timer.start(40);

    window.show();
    return app.exec();
}
