# Инструкция по сборке инструмента для ETL на основе сервера с Ubuntu 20.04

## Аннотация

Настоящая инструкция позволяет сконфигурировать инструмент для ETL (Extract -> Transform -> Load) для автоматизированного сбора, обработки и сохранения данных в базу данных PostgreSQL.

Особенностью инструмента является:
- WEB-интерфейс (доступ с любого ПК через браузер)
- Возможность создания ETL-скриптов на таких языках программирования как Python, R, Scala
- Разграничение прав доступа между различными пользователями
- Наличие инструмента для запуска скриптов ETL по расписанию в любое необходимое время с необходимой периодичностью

## Используемые решения

Для сборки ETL-инструмента используются следующие компоненты:
- ОС - Ubuntu 20.04 на виртуальном сервере
- Jupyter Lab - инструмент с WEB-интерфейсом для создания и запуска скриптов в режиме ноутбука
- Jupyter Hub - многопользовательский сервер для запуска Jupyter Notebooks (в которых аналитики будут непосредственно создавать ETL-скрипты)
- Conda - менеджер виртуальных окружений для запуска Python-кода
- Papermill - инструмент для запуска кода внутри Jupyter Notebooks вне среды Jupyter Lab (необходим для запуска Notebooks по расписанию из Cronicle)
- PETL и Pandas - для обработки табличных данных
- Cronicle - планировщик заданий с WEB-интерфейсом
- PostgreSQL - система управления базами данных

## Установка

**Ручная установка:**

[Инструкция по установке (step-by-step)](MANUALLY.md)

**Автоматическая установка:**

Выполнить команду

```
sudo apt-get update && sudo apt-get install git -y && git clone https://github.com/DmitriyKhodykin/ETLTool.git && cd ETLTool && sudo chmod +x *.sh && sudo ./fast_start.sh
```

## Управление пользователями

```
sudo user.sh
```

Будет выведена подсказка по ключам.

При создании пользователя создаётся его учётная запись для авторизации в Jupyter, Cronicle, PostgreSQL (так же создаётся таблица, название совпадает с логином).