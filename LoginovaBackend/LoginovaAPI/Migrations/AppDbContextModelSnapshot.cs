using LoginovaAPI.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations;

[DbContext(typeof(AppDbContext))]
partial class AppDbContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder
            .HasAnnotation("ProductVersion", "10.0.8")
            .HasAnnotation("Relational:MaxIdentifierLength", 63);

        modelBuilder.Entity("LoginovaAPI.Models.Cliente", b =>
        {
            b.Property<int>("Id")
                .ValueGeneratedOnAdd()
                .HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            b.Property<string>("Ciudad").IsRequired().HasColumnType("text");
            b.Property<string>("Direccion").IsRequired().HasColumnType("text");
            b.Property<string>("Nombre").IsRequired().HasColumnType("text");
            b.Property<string>("Telefono").IsRequired().HasColumnType("text");

            b.HasKey("Id");
            b.ToTable("Clientes");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Evidencia", b =>
        {
            b.Property<int>("Id")
                .ValueGeneratedOnAdd()
                .HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            b.Property<string>("Comentario").IsRequired().HasColumnType("text");
            b.Property<string>("FotoUrl").IsRequired().HasColumnType("text");
            b.Property<int>("RecogidaId").HasColumnType("integer");

            b.HasKey("Id");
            b.HasIndex("RecogidaId");
            b.ToTable("Evidencias");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Recogida", b =>
        {
            b.Property<int>("Id")
                .ValueGeneratedOnAdd()
                .HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            b.Property<int>("CantidadPaquetes").HasColumnType("integer");
            b.Property<int>("ClienteId").HasColumnType("integer");
            b.Property<string>("Estado").IsRequired().HasColumnType("text");
            b.Property<string>("Observaciones").IsRequired().HasColumnType("text");
            b.Property<int>("UsuarioId").HasColumnType("integer");

            b.HasKey("Id");
            b.HasIndex("ClienteId");
            b.HasIndex("UsuarioId");
            b.ToTable("Recogidas");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Usuario", b =>
        {
            b.Property<int>("Id")
                .ValueGeneratedOnAdd()
                .HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            b.Property<string>("Correo").IsRequired().HasColumnType("text");
            b.Property<string>("Nombre").IsRequired().HasColumnType("text");
            b.Property<string>("Password").IsRequired().HasColumnType("text");
            b.Property<string>("Rol").IsRequired().HasColumnType("text");

            b.HasKey("Id");
            b.HasIndex("Correo").IsUnique();
            b.HasData(
                new
                {
                    Id = 1,
                    Correo = "admin@loginova.com",
                    Nombre = "Administrador",
                    Password = "admin123",
                    Rol = "Administrador"
                });
            b.ToTable("Usuarios");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Evidencia", b =>
        {
            b.HasOne("LoginovaAPI.Models.Recogida", "Recogida")
                .WithMany("Evidencias")
                .HasForeignKey("RecogidaId")
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();

            b.Navigation("Recogida");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Recogida", b =>
        {
            b.HasOne("LoginovaAPI.Models.Cliente", "Cliente")
                .WithMany("Recogidas")
                .HasForeignKey("ClienteId")
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired();

            b.HasOne("LoginovaAPI.Models.Usuario", "Usuario")
                .WithMany("Recogidas")
                .HasForeignKey("UsuarioId")
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired();

            b.Navigation("Cliente");
            b.Navigation("Usuario");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Cliente", b =>
        {
            b.Navigation("Recogidas");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Recogida", b =>
        {
            b.Navigation("Evidencias");
        });

        modelBuilder.Entity("LoginovaAPI.Models.Usuario", b =>
        {
            b.Navigation("Recogidas");
        });
    }
}
