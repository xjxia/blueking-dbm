# Generated by Django 3.2.25 on 2025-02-18 02:06

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("redis_modules", "0004_clusterredismoduleassociate"),
    ]

    operations = [
        migrations.AlterField(
            model_name="clusterredismoduleassociate",
            name="id",
            field=models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID"),
        ),
        migrations.AlterField(
            model_name="tbredismodulesupport",
            name="id",
            field=models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID"),
        ),
    ]
